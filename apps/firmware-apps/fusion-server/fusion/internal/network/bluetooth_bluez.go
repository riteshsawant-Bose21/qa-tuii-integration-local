//go:build linux

package network

import (
	"context"
	"fmt"
	"sync"

	"github.com/godbus/dbus/v5"
	"github.com/godbus/dbus/v5/introspect"
	"github.com/godbus/dbus/v5/prop"
)

const (
	blueZAdapterInterface        = "org.bluez.Adapter1"
	blueZAdvertisementIface      = "org.bluez.LEAdvertisement1"
	blueZAdvertisingManagerIface = "org.bluez.LEAdvertisingManager1"
	blueZGattCharacteristicIface = "org.bluez.GattCharacteristic1"
	blueZGattManagerInterface    = "org.bluez.GattManager1"
	blueZGattServiceInterface    = "org.bluez.GattService1"
	blueZServiceName             = "org.bluez"
	dbusObjectManagerIface       = "org.freedesktop.DBus.ObjectManager"
	dbusPropertiesIface          = "org.freedesktop.DBus.Properties"
	fusionBlueZRootPath          = dbus.ObjectPath("/com/bose/fusion/bluetooth")
)

var objectManagerIntrospection = introspect.Interface{
	Name: dbusObjectManagerIface,
	Methods: []introspect.Method{
		{
			Name: "GetManagedObjects",
			Args: []introspect.Arg{
				{Name: "objects", Type: "a{oa{sa{sv}}}", Direction: "out"},
			},
		},
	},
}

type blueZTransport struct {
	adapterPath    dbus.ObjectPath
	advertPath     dbus.ObjectPath
	advertisement  *blueZAdvertisement
	app            *blueZApplication
	appPath        dbus.ObjectPath
	bridge         *bluetoothBridge
	characterPath  dbus.ObjectPath
	characteristic *blueZCharacteristic
	conn           *dbus.Conn
	props          []*prop.Properties
	service        *blueZService
	servicePath    dbus.ObjectPath
}

type blueZApplication struct {
	objects map[dbus.ObjectPath]blueZManagedObject
}

type blueZManagedObject interface {
	managedProperties() map[string]map[string]dbus.Variant
}

type blueZService struct {
	uuid  string
	chars []dbus.ObjectPath
}

type blueZAdvertisement struct {
	name        string
	serviceUUID string
}

type blueZCharacteristic struct {
	bridge   *bluetoothBridge
	cancel   context.CancelFunc
	cancelMu sync.Mutex
	conn     *dbus.Conn
	device   dbus.ObjectPath
	path     dbus.ObjectPath
	props    *prop.Properties
	service  dbus.ObjectPath
}

type blueZNotificationSession struct {
	ctx   context.Context
	close func() error
	write func([]byte) error
}

func (s blueZNotificationSession) Context() context.Context { return s.ctx }
func (s blueZNotificationSession) Close() error             { return s.close() }
func (s blueZNotificationSession) Write(data []byte) error  { return s.write(data) }

func newBlueZTransport(name string, serviceUUID string, characterUUID string, bridge *bluetoothBridge) (*blueZTransport, error) {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return nil, err
	}

	adapterPath, err := findBlueZAdapter(conn)
	if err != nil {
		_ = conn.Close()
		return nil, err
	}

	appPath := fusionBlueZRootPath
	servicePath := dbus.ObjectPath(string(appPath) + "/service0")
	charPath := dbus.ObjectPath(string(servicePath) + "/char0")
	advertPath := dbus.ObjectPath(string(appPath) + "/advertisement0")

	service := &blueZService{
		uuid:  serviceUUID,
		chars: []dbus.ObjectPath{charPath},
	}

	characteristic := &blueZCharacteristic{
		bridge:  bridge,
		conn:    conn,
		path:    charPath,
		service: servicePath,
	}

	advertisement := &blueZAdvertisement{
		name:        name,
		serviceUUID: serviceUUID,
	}

	app := &blueZApplication{
		objects: map[dbus.ObjectPath]blueZManagedObject{},
	}

	transport := &blueZTransport{
		adapterPath:    adapterPath,
		advertPath:     advertPath,
		advertisement:  advertisement,
		app:            app,
		appPath:        appPath,
		bridge:         bridge,
		characterPath:  charPath,
		characteristic: characteristic,
		conn:           conn,
		service:        service,
		servicePath:    servicePath,
	}

	serviceProps, err := prop.Export(conn, servicePath, prop.Map{
		blueZGattServiceInterface: {
			"UUID":    {Value: serviceUUID, Emit: prop.EmitConst},
			"Primary": {Value: true, Emit: prop.EmitConst},
		},
	})
	if err != nil {
		_ = conn.Close()
		return nil, err
	}

	charProps, err := prop.Export(conn, charPath, prop.Map{
		blueZGattCharacteristicIface: {
			"UUID":      {Value: characterUUID, Emit: prop.EmitConst},
			"Service":   {Value: servicePath, Emit: prop.EmitConst},
			"Flags":     {Value: []string{"read", "write", "notify"}, Emit: prop.EmitConst},
			"Notifying": {Value: false, Emit: prop.EmitTrue},
			"Value":     {Value: []byte{}, Emit: prop.EmitTrue},
		},
	})
	if err != nil {
		_ = conn.Close()
		return nil, err
	}
	characteristic.props = charProps

	advertProps, err := prop.Export(conn, advertPath, prop.Map{
		blueZAdvertisementIface: {
			"Type":         {Value: "peripheral", Emit: prop.EmitConst},
			"ServiceUUIDs": {Value: []string{serviceUUID}, Emit: prop.EmitConst},
			"LocalName":    {Value: name, Emit: prop.EmitConst},
		},
	})
	if err != nil {
		_ = conn.Close()
		return nil, err
	}

	transport.props = []*prop.Properties{serviceProps, charProps, advertProps}
	app.objects[servicePath] = service
	app.objects[charPath] = characteristic
	return transport, nil
}

func (t *blueZTransport) serve(ctx context.Context) error {
	if err := t.exportObjects(); err != nil {
		return err
	}
	if err := powerAdapter(t.conn, t.adapterPath); err != nil {
		t.bridge.logger.Warn("Failed to power BlueZ adapter: %v", err)
	}
	if err := t.registerApplication(); err != nil {
		t.stop()
		return err
	}
	if err := t.registerAdvertisement(); err != nil {
		_ = t.unregisterApplication()
		t.stop()
		return err
	}

	t.bridge.logger.Info("BlueZ BLE backend active on adapter %s", t.adapterPath)
	<-ctx.Done()
	return ctx.Err()
}

func (t *blueZTransport) stop() {
	if t.characteristic != nil {
		_ = t.characteristic.shutdown()
	}
	if t.conn != nil {
		_ = t.unregisterAdvertisement()
		_ = t.unregisterApplication()
		t.unexportObjects()
		_ = t.conn.Close()
		t.conn = nil
	}
}

func (t *blueZTransport) exportObjects() error {
	if err := t.conn.Export(t.app, t.appPath, dbusObjectManagerIface); err != nil {
		return err
	}
	if err := t.conn.Export(t.service, t.servicePath, blueZGattServiceInterface); err != nil {
		return err
	}
	if err := t.conn.Export(t.characteristic, t.characterPath, blueZGattCharacteristicIface); err != nil {
		return err
	}
	if err := t.conn.Export(t.advertisement, t.advertPath, blueZAdvertisementIface); err != nil {
		return err
	}

	for _, spec := range []struct {
		path dbus.ObjectPath
		node *introspect.Node
	}{
		{path: t.appPath, node: t.app.introspectionNode()},
		{path: t.servicePath, node: t.service.introspectionNode(t.props[0])},
		{path: t.characterPath, node: t.characteristic.introspectionNode()},
		{path: t.advertPath, node: t.advertisement.introspectionNode(t.props[2])},
	} {
		if err := t.conn.Export(introspect.NewIntrospectable(spec.node), spec.path, "org.freedesktop.DBus.Introspectable"); err != nil {
			return err
		}
	}

	return nil
}

func (t *blueZTransport) unexportObjects() {
	for _, path := range []dbus.ObjectPath{t.appPath, t.servicePath, t.characterPath, t.advertPath} {
		_ = t.conn.Export(nil, path, dbusObjectManagerIface)
		_ = t.conn.Export(nil, path, blueZGattServiceInterface)
		_ = t.conn.Export(nil, path, blueZGattCharacteristicIface)
		_ = t.conn.Export(nil, path, blueZAdvertisementIface)
		_ = t.conn.Export(nil, path, "org.freedesktop.DBus.Introspectable")
		_ = t.conn.Export(nil, path, dbusPropertiesIface)
	}
}

func (t *blueZTransport) registerApplication() error {
	obj := t.conn.Object(blueZServiceName, t.adapterPath)
	call := obj.Call(blueZGattManagerInterface+".RegisterApplication", 0, t.appPath, map[string]dbus.Variant{})
	if call.Err != nil {
		return fmt.Errorf("registering BlueZ application: %w", call.Err)
	}
	return nil
}

func (t *blueZTransport) unregisterApplication() error {
	if t.conn == nil {
		return nil
	}
	obj := t.conn.Object(blueZServiceName, t.adapterPath)
	call := obj.Call(blueZGattManagerInterface+".UnregisterApplication", 0, t.appPath)
	return call.Err
}

func (t *blueZTransport) registerAdvertisement() error {
	obj := t.conn.Object(blueZServiceName, t.adapterPath)
	call := obj.Call(blueZAdvertisingManagerIface+".RegisterAdvertisement", 0, t.advertPath, map[string]dbus.Variant{})
	if call.Err != nil {
		return fmt.Errorf("registering BlueZ advertisement: %w", call.Err)
	}
	return nil
}

func (t *blueZTransport) unregisterAdvertisement() error {
	if t.conn == nil {
		return nil
	}
	obj := t.conn.Object(blueZServiceName, t.adapterPath)
	call := obj.Call(blueZAdvertisingManagerIface+".UnregisterAdvertisement", 0, t.advertPath)
	return call.Err
}

func findBlueZAdapter(conn *dbus.Conn) (dbus.ObjectPath, error) {
	var managedObjects map[dbus.ObjectPath]map[string]map[string]dbus.Variant
	call := conn.Object(blueZServiceName, "/").Call(dbusObjectManagerIface+".GetManagedObjects", 0)
	if call.Err != nil {
		return "", fmt.Errorf("querying BlueZ managed objects: %w", call.Err)
	}
	if err := call.Store(&managedObjects); err != nil {
		return "", err
	}
	for path, ifaces := range managedObjects {
		if _, ok := ifaces[blueZGattManagerInterface]; !ok {
			continue
		}
		if _, ok := ifaces[blueZAdvertisingManagerIface]; !ok {
			continue
		}
		return path, nil
	}
	return "", fmt.Errorf("no BlueZ adapter with GATT and advertising managers found")
}

func powerAdapter(conn *dbus.Conn, adapterPath dbus.ObjectPath) error {
	call := conn.Object(blueZServiceName, adapterPath).Call(
		dbusPropertiesIface+".Set",
		0,
		blueZAdapterInterface,
		"Powered",
		dbus.MakeVariant(true),
	)
	return call.Err
}

func (a *blueZApplication) GetManagedObjects() (map[dbus.ObjectPath]map[string]map[string]dbus.Variant, *dbus.Error) {
	objects := make(map[dbus.ObjectPath]map[string]map[string]dbus.Variant, len(a.objects))
	for path, obj := range a.objects {
		objects[path] = obj.managedProperties()
	}
	return objects, nil
}

func (a *blueZApplication) introspectionNode() *introspect.Node {
	return &introspect.Node{
		Name: string(fusionBlueZRootPath),
		Interfaces: []introspect.Interface{
			introspect.IntrospectData,
			objectManagerIntrospection,
		},
		Children: []introspect.Node{
			{Name: "service0"},
		},
	}
}

func (s *blueZService) managedProperties() map[string]map[string]dbus.Variant {
	return map[string]map[string]dbus.Variant{
		blueZGattServiceInterface: {
			"UUID":    dbus.MakeVariant(s.uuid),
			"Primary": dbus.MakeVariant(true),
		},
	}
}

func (s *blueZService) introspectionNode(props *prop.Properties) *introspect.Node {
	return &introspect.Node{
		Name: "service0",
		Interfaces: []introspect.Interface{
			introspect.IntrospectData,
			prop.IntrospectData,
			{
				Name:       blueZGattServiceInterface,
				Properties: props.Introspection(blueZGattServiceInterface),
			},
		},
		Children: []introspect.Node{{Name: "char0"}},
	}
}

func (a *blueZAdvertisement) Release() *dbus.Error {
	return nil
}

func (a *blueZAdvertisement) managedProperties() map[string]map[string]dbus.Variant {
	return map[string]map[string]dbus.Variant{
		blueZAdvertisementIface: {
			"Type":         dbus.MakeVariant("peripheral"),
			"ServiceUUIDs": dbus.MakeVariant([]string{a.serviceUUID}),
			"LocalName":    dbus.MakeVariant(a.name),
		},
	}
}

func (a *blueZAdvertisement) introspectionNode(props *prop.Properties) *introspect.Node {
	return &introspect.Node{
		Name: "advertisement0",
		Interfaces: []introspect.Interface{
			introspect.IntrospectData,
			prop.IntrospectData,
			{
				Name:       blueZAdvertisementIface,
				Methods:    introspect.Methods(a),
				Properties: props.Introspection(blueZAdvertisementIface),
			},
		},
	}
}

func (c *blueZCharacteristic) managedProperties() map[string]map[string]dbus.Variant {
	return map[string]map[string]dbus.Variant{
		blueZGattCharacteristicIface: {
			"UUID":      dbus.MakeVariant(c.props.GetMust(blueZGattCharacteristicIface, "UUID")),
			"Service":   dbus.MakeVariant(c.service),
			"Flags":     dbus.MakeVariant([]string{"read", "write", "notify"}),
			"Notifying": dbus.MakeVariant(c.props.GetMust(blueZGattCharacteristicIface, "Notifying")),
			"Value":     dbus.MakeVariant(c.props.GetMust(blueZGattCharacteristicIface, "Value")),
		},
	}
}

func (c *blueZCharacteristic) introspectionNode() *introspect.Node {
	return &introspect.Node{
		Name: "char0",
		Interfaces: []introspect.Interface{
			introspect.IntrospectData,
			prop.IntrospectData,
			{
				Name:       blueZGattCharacteristicIface,
				Methods:    introspect.Methods(c),
				Properties: c.props.Introspection(blueZGattCharacteristicIface),
			},
		},
	}
}

func (c *blueZCharacteristic) ReadValue(options map[string]dbus.Variant) ([]byte, *dbus.Error) {
	c.trackDevice(options)
	value, ok := c.props.GetMust(blueZGattCharacteristicIface, "Value").([]byte)
	if !ok {
		return nil, dbus.MakeFailedError(fmt.Errorf("invalid characteristic value type"))
	}
	out := make([]byte, len(value))
	copy(out, value)
	return out, nil
}

func (c *blueZCharacteristic) WriteValue(value []byte, options map[string]dbus.Variant) *dbus.Error {
	c.trackDevice(options)
	incoming := append([]byte(nil), value...)
	c.bridge.handleWrite(incoming)
	return nil
}

func (c *blueZCharacteristic) StartNotify() *dbus.Error {
	c.cancelMu.Lock()
	defer c.cancelMu.Unlock()
	if c.cancel != nil {
		return nil
	}
	ctx, cancel := context.WithCancel(context.Background())
	c.cancel = cancel
	c.props.SetMust(blueZGattCharacteristicIface, "Notifying", true)
	go c.bridge.runNotificationSession(blueZNotificationSession{
		ctx: ctx,
		close: func() error {
			return c.shutdown()
		},
		write: func(data []byte) error {
			out := append([]byte(nil), data...)
			c.props.SetMust(blueZGattCharacteristicIface, "Value", out)
			return nil
		},
	})
	return nil
}

func (c *blueZCharacteristic) StopNotify() *dbus.Error {
	if err := c.shutdown(); err != nil {
		return dbus.MakeFailedError(err)
	}
	return nil
}

func (c *blueZCharacteristic) shutdown() error {
	c.cancelMu.Lock()
	device := c.device
	cancel := c.cancel
	c.cancel = nil
	if cancel == nil {
		c.props.SetMust(blueZGattCharacteristicIface, "Notifying", false)
		c.cancelMu.Unlock()
		return c.disconnectDevice(device)
	}
	c.cancelMu.Unlock()
	cancel()
	c.props.SetMust(blueZGattCharacteristicIface, "Notifying", false)
	return c.disconnectDevice(device)
}

func (c *blueZCharacteristic) disconnectDevice(device dbus.ObjectPath) error {
	if c.conn == nil || !device.IsValid() {
		return nil
	}
	call := c.conn.Object(blueZServiceName, device).Call("org.bluez.Device1.Disconnect", 0)
	if call.Err != nil {
		if dbusErr, ok := call.Err.(*dbus.Error); ok && dbusErr.Name == "org.bluez.Error.NotConnected" {
			return nil
		}
		return call.Err
	}
	return nil
}

func (c *blueZCharacteristic) trackDevice(options map[string]dbus.Variant) {
	deviceVariant, ok := options["device"]
	if !ok {
		return
	}
	device, ok := deviceVariant.Value().(dbus.ObjectPath)
	if !ok || !device.IsValid() {
		return
	}
	c.cancelMu.Lock()
	c.device = device
	c.cancelMu.Unlock()
}
