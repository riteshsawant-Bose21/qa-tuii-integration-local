Map<String, dynamic> schemeData = {
  "devices": [
    {
      "connections_device_in": [],
      "connections_device_out": [],
      "cores": [
        {
          "block_ids": [
            "SOURCE1773294428396210524",
            "GATE14772717",
            "FUNC585446300_source_selector",
            "ZONE177340417108289766_source_selector",
            "TONECONTROL1773404171083637039",
            "GAIN1773404171083331566",
            "DELAY1773404171084542222",
            "PEQ1773404171084101881",
            "CIRCUIT1773165733860273786_source_selector",
            "TONECONTROL1773750291925882470",
            "CIRCUIT1773165733860273786"
          ],
          "label": "fusion_c1: 1 (core 1)",
          "util_algs": 0.000050238917485018,
          "util_device_connect": 0,
          "util_task_connect": 0.000016,
          "util_total": 0.000066238917485018
        },
        {
          "block_ids": [],
          "label": "fusion_c1: 1 (core 2)",
          "util_algs": 0,
          "util_device_connect": 0,
          "util_task_connect": 0,
          "util_total": 0
        },
        {
          "block_ids": [],
          "label": "fusion_c1: 1 (core 3)",
          "util_algs": 0,
          "util_device_connect": 0,
          "util_task_connect": 0,
          "util_total": 0
        }
      ],
      "cost": 120,
      "device_type": "fusion_c1",
      "dsp_static_config": {
        "audio_tasks": [
          {
            "block_connections": [
              {
                "destination_block": "GATE14772717",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "SOURCE1773294428396210524"
              },
              {
                "destination_block": "GATE14772717_jack_out",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "GATE14772717"
              }
            ],
            "blocks": [
              {
                "algorithm": "jack_in",
                "name": "SOURCE1773294428396210524",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "SOURCE1773294428396210524"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "out"
                  }
                ]
              },
              {
                "algorithm": "gate",
                "name": "GATE14772717",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "jack_out",
                "name": "GATE14772717_jack_out",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "SOURCE1773294428396210524"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              }
            ],
            "name": "SOURCE1773294428396210524",
            "property_settings": [
              {
                "name": "sample_rate",
                "value": 48000
              },
              {
                "name": "frame_size",
                "value": 32
              },
              {
                "name": "jack_client_name",
                "value": "SOURCE1773294428396210524"
              },
              {
                "name": "cpu_affinity",
                "value": 1
              }
            ]
          },
          {
            "block_connections": [
              {
                "destination_block": "FUNC585446300_source_selector",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "FUNC585446300_source_selector_jack_in"
              },
              {
                "destination_block": "FUNC585446300_source_selector_jack_out",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "FUNC585446300_source_selector"
              }
            ],
            "blocks": [
              {
                "algorithm": "jack_in",
                "name": "FUNC585446300_source_selector_jack_in",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "FUNC585446300"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "out"
                  }
                ]
              },
              {
                "algorithm": "source_selector",
                "name": "FUNC585446300_source_selector",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              },
              {
                "algorithm": "jack_out",
                "name": "FUNC585446300_source_selector_jack_out",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "FUNC585446300"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              }
            ],
            "name": "FUNC585446300",
            "property_settings": [
              {
                "name": "sample_rate",
                "value": 48000
              },
              {
                "name": "frame_size",
                "value": 32
              },
              {
                "name": "jack_client_name",
                "value": "FUNC585446300"
              },
              {
                "name": "cpu_affinity",
                "value": 1
              }
            ]
          },
          {
            "block_connections": [
              {
                "destination_block": "TONECONTROL1773404171083637039",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "ZONE177340417108289766_source_selector"
              },
              {
                "destination_block": "GAIN1773404171083331566",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "TONECONTROL1773404171083637039"
              },
              {
                "destination_block": "ZONE177340417108289766_source_selector",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "ZONE177340417108289766_source_selector_jack_in"
              },
              {
                "destination_block": "GAIN1773404171083331566_jack_out",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "GAIN1773404171083331566"
              }
            ],
            "blocks": [
              {
                "algorithm": "jack_in",
                "name": "ZONE177340417108289766_source_selector_jack_in",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "ZONE177340417108289766"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "out"
                  }
                ]
              },
              {
                "algorithm": "source_selector",
                "name": "ZONE177340417108289766_source_selector",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              },
              {
                "algorithm": "tone_control",
                "name": "TONECONTROL1773404171083637039",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "gain",
                "name": "GAIN1773404171083331566",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "jack_out",
                "name": "GAIN1773404171083331566_jack_out",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "ZONE177340417108289766"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              }
            ],
            "name": "ZONE177340417108289766",
            "property_settings": [
              {
                "name": "sample_rate",
                "value": 48000
              },
              {
                "name": "frame_size",
                "value": 32
              },
              {
                "name": "jack_client_name",
                "value": "ZONE177340417108289766"
              },
              {
                "name": "cpu_affinity",
                "value": 1
              }
            ]
          },
          {
            "block_connections": [
              {
                "destination_block": "PEQ1773404171084101881",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "DELAY1773404171084542222"
              },
              {
                "destination_block": "DELAY1773404171084542222",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "DELAY1773404171084542222_jack_in"
              },
              {
                "destination_block": "PEQ1773404171084101881_jack_out",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "PEQ1773404171084101881"
              }
            ],
            "blocks": [
              {
                "algorithm": "jack_in",
                "name": "DELAY1773404171084542222_jack_in",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "pZONE177340417108289766"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "out"
                  }
                ]
              },
              {
                "algorithm": "delay",
                "name": "DELAY1773404171084542222",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "peq",
                "name": "PEQ1773404171084101881",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "bands",
                    "value": 3
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "jack_out",
                "name": "PEQ1773404171084101881_jack_out",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "pZONE177340417108289766"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              }
            ],
            "name": "pZONE177340417108289766",
            "property_settings": [
              {
                "name": "sample_rate",
                "value": 48000
              },
              {
                "name": "frame_size",
                "value": 32
              },
              {
                "name": "jack_client_name",
                "value": "pZONE177340417108289766"
              },
              {
                "name": "cpu_affinity",
                "value": 1
              }
            ]
          },
          {
            "block_connections": [
              {
                "destination_block": "TONECONTROL1773750291925882470",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "CIRCUIT1773165733860273786_source_selector"
              },
              {
                "destination_block": "CIRCUIT1773165733860273786",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "TONECONTROL1773750291925882470"
              },
              {
                "destination_block": "CIRCUIT1773165733860273786_source_selector",
                "input_channel": 1,
                "input_terminal": "in",
                "output_channel": 1,
                "output_terminal": "out",
                "source_block": "CIRCUIT1773165733860273786_source_selector_jack_in"
              }
            ],
            "blocks": [
              {
                "algorithm": "jack_in",
                "name": "CIRCUIT1773165733860273786_source_selector_jack_in",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "CIRCUIT1773165733860273786"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "out"
                  }
                ]
              },
              {
                "algorithm": "source_selector",
                "name": "CIRCUIT1773165733860273786_source_selector",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              },
              {
                "algorithm": "tone_control",
                "name": "TONECONTROL1773750291925882470",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "channels",
                    "value": 1
                  }
                ]
              },
              {
                "algorithm": "jack_out",
                "name": "CIRCUIT1773165733860273786",
                "property_settings": [
                  {
                    "name": "sample_rate",
                    "value": 48000
                  },
                  {
                    "name": "frame_size",
                    "value": 32
                  },
                  {
                    "name": "client_name",
                    "value": "CIRCUIT1773165733860273786"
                  }
                ],
                "terminal_channels": [
                  {
                    "channels": 1,
                    "name": "in"
                  }
                ]
              }
            ],
            "name": "CIRCUIT1773165733860273786",
            "property_settings": [
              {
                "name": "sample_rate",
                "value": 48000
              },
              {
                "name": "frame_size",
                "value": 32
              },
              {
                "name": "jack_client_name",
                "value": "CIRCUIT1773165733860273786"
              },
              {
                "name": "cpu_affinity",
                "value": 1
              }
            ]
          }
        ],
        "parameter_settings": [],
        "session": {
          "property_settings": [
            {
              "name": "sample_rate",
              "value": 48000
            },
            {
              "name": "frame_size",
              "value": 32
            }
          ]
        },
        "task_connections": [
          {
            "destination_task": "FUNC585446300",
            "input_block": "FUNC585446300_source_selector_jack_in",
            "input_channel": 1,
            "output_block": "GATE14772717_jack_out",
            "output_channel": 1,
            "source_task": "SOURCE1773294428396210524"
          },
          {
            "destination_task": "ZONE177340417108289766",
            "input_block": "ZONE177340417108289766_source_selector_jack_in",
            "input_channel": 1,
            "output_block": "FUNC585446300_source_selector_jack_out",
            "output_channel": 1,
            "source_task": "FUNC585446300"
          },
          {
            "destination_task": "pZONE177340417108289766",
            "input_block": "DELAY1773404171084542222_jack_in",
            "input_channel": 1,
            "output_block": "GAIN1773404171083331566_jack_out",
            "output_channel": 1,
            "source_task": "ZONE177340417108289766"
          },
          {
            "destination_task": "CIRCUIT1773165733860273786",
            "input_block": "CIRCUIT1773165733860273786_source_selector_jack_in",
            "input_channel": 1,
            "output_block": "PEQ1773404171084101881_jack_out",
            "output_channel": 1,
            "source_task": "pZONE177340417108289766"
          },
          {
            "destination_task": "SOURCE1773294428396210524",
            "input_block": "SOURCE1773294428396210524",
            "input_channel": 1,
            "output_block": "capture",
            "output_channel": 1,
            "source_task": "system"
          },
          {
            "destination_task": "system",
            "input_block": "playback",
            "input_channel": 1,
            "output_block": "CIRCUIT1773165733860273786",
            "output_channel": 1,
            "source_task": "CIRCUIT1773165733860273786"
          }
        ]
      },
      "id": "FUSIONDSP419486553",
      "label": "fusion_c1: 1 - FUSIONDSP419486553",
      "location": ""
    }
  ],
  "wall_controller_config": {
    "controllers": [
      {
        "id": "CTRL1762958340064766236",
        "name": "Controller 1",
        "zoneIds": [
          "zone1762957501115776"
        ]
      }
    ],
    "zones": [
      {
        "gain": {
          "default_gain_value": "50",
          "default_mute_value": "50",
          "gainID": "gain1762957501115",
          "max_value": "100",
          "min_value": "0"
        },
        "id": "zone1762957501115776",
        "name": "Zone 1",
        "ono": {
          "gain": 8002,
          "mute": 8003,
          "sourceSelector": 8004,
          "zone": 8001
        },
        "sources": [
          {
            "index": 0,
            "sourceId": "MIC001",
            "sourceName": "Mic 1"
          },
          {
            "index": 1,
            "sourceId": "MIC02",
            "sourceName": "Mic 2"
          }
        ]
      },
      {
        "gain": {
          "default_gain_value": "50",
          "default_mute_value": "50",
          "gainID": "gain1762957501116",
          "max_value": "100",
          "min_value": "0"
        },
        "id": "zone1762957501115776",
        "name": "Zone 2",
        "ono": {
          "gain": 8002,
          "mute": 8003,
          "sourceSelector": 8004,
          "zone": 8002
        },
        "sources": [
          {
            "index": 0,
            "sourceId": "BOOMMIC001",
            "sourceName": "Boom Mic 1"
          }
        ]
      }
    ]
  }
};