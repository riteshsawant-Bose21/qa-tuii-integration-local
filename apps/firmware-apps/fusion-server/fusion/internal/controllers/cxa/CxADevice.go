package cxa

import (
	"encoding/binary"
	"fmt"
	"net"
)

const (
	NORMALIZED_MAX = 65535

	REMOTE_CC1_MAX_VOLUME = 2450
	REMOTE_CC1_MIN_VOLUME = 70

	REMOTE_CC2_MAX_VOLUME_A = 2450
	REMOTE_CC2_MAX_VOLUME_B = 1850
	REMOTE_CC2_MIN_VOLUME   = 50
	REMOTE_CC2_SEL_VOLUME_B = 3500

	REMOTE_CC3_MAX_VOLUME = 5
	REMOTE_CC3_MIN_VOLUME = 1937
	REMOTE_CC3_SEL_INPUT  = 3650
)

type ControllerType int

const (
	CC1 ControllerType = iota + 1
	CC2
	CC3
)

type Device struct {
	conn        net.Conn
	ctrlType    ControllerType
	position    int
	currentVol  float64
	inputSelect int
}

func NewDevice(controllerType ControllerType, position int, address string) (*Device, error) {
	conn, err := net.Dial("tcp", address)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to server: %v", err)
	}

	return &Device{
		conn:        conn,
		ctrlType:    controllerType,
		position:    position,
		currentVol:  0.5, // Start at middle volume
		inputSelect: 1,   // Start with first input
	}, nil
}

func (vc *Device) Close() {
	if vc.conn != nil {
		vc.conn.Close()
	}
}

func (vc *Device) sendAnalogValues() error {
	values := make([]uint32, 5)

	switch vc.ctrlType {
	case CC1:
		values[vc.position-1] = denormalizeCC1Volume(vc.currentVol)

	case CC2:
		if vc.position == 1 {
			values[0] = denormalizeCC2Volume(vc.currentVol, vc.inputSelect)
			if vc.inputSelect == 2 {
				values[3] = REMOTE_CC2_SEL_VOLUME_B
			}
		} else if vc.position == 2 {
			values[1] = denormalizeCC2Volume(vc.currentVol, vc.inputSelect)
			if vc.inputSelect == 2 {
				values[4] = REMOTE_CC2_SEL_VOLUME_B
			}
		}

	case CC3:
		if vc.position == 1 {
			values[0] = denormalizeCC3Volume(vc.currentVol)
			for i := 1; i <= 4; i++ {
				if i == vc.inputSelect {
					values[i] = REMOTE_CC3_SEL_INPUT - 100
				} else {
					values[i] = REMOTE_CC3_SEL_INPUT + 100
				}
			}
		}
	}

	buf := make([]byte, 20)
	for i, v := range values {
		binary.BigEndian.PutUint32(buf[i*4:(i+1)*4], v)
	}
	_, err := vc.conn.Write(buf)
	return err
}

func (vc *Device) SetVolume(vol float64) error {
	if vol < 0.0 || vol > 1.0 {
		return fmt.Errorf("volume must be between 0.0 and 1.0")
	}
	vc.currentVol = vol
	return vc.sendAnalogValues()
}

func (vc *Device) SetInput(input int) error {
	maxInputs := 1
	switch vc.ctrlType {
	case CC2:
		maxInputs = 2
	case CC3:
		maxInputs = 4
	}

	if input < 1 || input > maxInputs {
		return fmt.Errorf("invalid input selection for controller type")
	}

	vc.inputSelect = input
	return vc.sendAnalogValues()
}
