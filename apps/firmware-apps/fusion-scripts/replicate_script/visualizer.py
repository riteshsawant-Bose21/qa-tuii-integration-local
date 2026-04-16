
# changed to add color, 
# changed to use block['name'] instead of json_block['label']
# changed to use json_output['result']['devices'] instead of json_output['devices']
# changed to not create DOT files when exporting images or image data
# changed to visualize task and device connections for output

import base64
import io
import json

import graphviz

def visualize_config(json_config, output_file, vir=False, save_image=True):
    '''
    Converts JSON input configuration to a block diagram using graphviz dot
    format.

    Input
        - json_config: JSON input config (dict)
        - output_file: output image filename if to save visualization
        - vir: if the given JSON configuration is for virtual blocks, bool
        - save_image: save image if set, bool
    Output
        - base64_image: base64 image format of the visualization of input config
    '''
    dot_buffer = io.StringIO()
    dot_buffer.write('digraph g {\n')
    dot_buffer.write('  graph [rankdir = "LR"];\n')

    for json_block in json_config['blocks']:
        dot_buffer.write('  "' + str(json_block['id']) + '"')
        dot_buffer.write('[ label = "' + json_block['name'] +
                       ' (' + json_block['algorithm'] +
                       ')" shape = "Mrecord"];\n')

    # if visualizing connections for virtual blocks (use connections_in and connections_out fields)
    if vir:
        for json_block in json_config['blocks']:
            for connection in json_block['connections_in']:
                dot_buffer.write('  "' + str(connection) + '" -> "' +
                            str(json_block['id']) + '";\n')
    # not for virtual blocks (use block_connections list)
    else:
        for connection in json_config['block_connections']:
            dot_buffer.write('  "' + connection["source_block"] + '" -> "' +
                            connection["destination_block"] + '";\n')

    dot_buffer.write('}\n')
    dot_string = dot_buffer.getvalue()
    dot = graphviz.Source(dot_string)
    png_data = dot.pipe(format="png")
    # save input config visualization
    if save_image:
        with open(output_file, "wb") as f:
            f.write(png_data)
    # to base64
    base64_image = base64.b64encode(png_data).decode()
    return base64_image


def get_property(block, property):
    for prop in block.get("property_settings", []):
        if prop.get("name") == property:
            return prop.get("value")
    return 0

def if_source_port_match(block, source_port):
    for prop in block.get("property_settings", []):
        if prop.get("name") == "device_name" and prop.get("value", "").endswith(f"_{source_port}"):
            return True
    return False

def get_fc_src_blk_from_dev(dev, source_port):
    for task in dev["dsp_static_config"]["audio_tasks"]:
        for blk in task["blocks"]:
            if "alsa_out" in blk["algorithm"] and if_source_port_match(blk, source_port):
                return blk["name"]
            
def get_fc_dst_blk_from_dev(dev, source_port):
    for task in dev["dsp_static_config"]["audio_tasks"]:
        for blk in task["blocks"]:
            if "alsa_in" in blk["algorithm"] and if_source_port_match(blk, source_port):
                return blk["name"]

def get_fc_src_dst_blks(data, src_dev, dst_dev, source_port):
    for dev in data["devices"]:
        if dev["id"] == src_dev:
            src_blk = get_fc_src_blk_from_dev(dev, source_port)
        if dev["id"] == dst_dev:
            dst_blk = get_fc_dst_blk_from_dev(dev, source_port)
    return src_blk, dst_blk

def visualize_output_dsp(json_output, output_file, save_image=True):
    '''
    Given the output configuration from the
    resource manager, create a block diagram using graphviz dot format, 
    decomposed among the processors in the system. The block diagram represents
    the dsp configuration with extra blocks for task connecitons and fusion connect.

    Input
        - json_output: resource manager JSON output config (dict)
        - output_file: output image filename if to save visualization
        - save_image: save image if set, bool
    Output
        - base64_image: base64 image format of the visualization of output config
    '''
    # Create a Graphviz Digraph
    dot = graphviz.Digraph("DSP_Block_Diagram", format="png")
    dot.attr(compound="true", rankdir="LR")

    # Create clusters for locations, devices, cores, and blocks
    if "result" not in json_output:
        json_result = json_output
    else:
        json_result = json_output["result"]
    for device in json_result["devices"]:
        location = device["location"]
        device_id = device["id"]
        device_label = device["label"]

        with dot.subgraph(name=f"cluster_{location}") as loc_cluster:
            loc_cluster.attr(label=location, style="filled", color="lightblue")
            with loc_cluster.subgraph(name=f"cluster_{device_id}") as dev_cluster:
                dev_cluster.attr(label=device_label, style="filled", color="lightgrey")

                # Group blocks by core
                core_blocks = {}
                for task in device["dsp_static_config"]["audio_tasks"]:
                    cpu_affinity = None
                    for prop in task.get("property_settings", []):
                        if prop["name"] == "cpu_affinity":
                            cpu_affinity = prop["value"]
                            break
                    for block in task["blocks"]:
                        core_blocks.setdefault(cpu_affinity, []).append(block)

                # Add capture and playback node
                dev_cluster.node(f"capture_{device_id}", label="capture", shape="plaintext")
                dev_cluster.node(f"playback_{device_id}", label="playback", shape="plaintext")

                # Create core clusters
                for core_id, blocks in core_blocks.items():
                    with dev_cluster.subgraph(name=f"cluster_{device_id}_core{core_id}") as core_cluster:
                        core_cluster.attr(label=f"Core {core_id}", style="filled", color="white")
                        for block in blocks:
                            block_name = block["name"]
                            algorithm = block["algorithm"]
                            node_id = block_name
                            # Create table label
                            label = f"<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>"
                            label += f"<TR><TD WIDTH='120'>{block_name} ({algorithm})</TD></TR>"
                            port_index = 0
                            # don't visualize terminals for meter blocks, too many channels to display
                            if not (block_name.endswith("meter") or block_name.endswith("meter_jack_in")):
                                if "terminal_channels" in block:
                                    for terminal in block.get("terminal_channels", []):
                                        term_name = terminal["name"]
                                        channels = terminal["channels"]
                                        for ch in range(1, channels + 1):
                                            port_index += 1
                                            port_id = f"port{port_index}"
                                            label += f"<TR><TD WIDTH='120' PORT='{port_id}'>{term_name}:{ch}</TD></TR>"
                                else:
                                    for ch in range(1, get_property(block, "channels") + 1):
                                        port_index += 1
                                        port_id = f"port{port_index}"
                                        label += f"<TR><TD WIDTH='120' PORT='{port_id}'>in:{ch}</TD></TR>"
                                    for ch in range(1, get_property(block, "channels") + 1):
                                        port_index += 1
                                        port_id = f"port{port_index}"
                                        label += f"<TR><TD WIDTH='120' PORT='{port_id}'>out:{ch}</TD></TR>"
                            label += "</TABLE>>"
                            core_cluster.node(node_id, label=label, shape="plaintext")

    # Connections
    for device in json_result["devices"]:
        device_id = device["id"]
        # Draw task_connections
        for conn in device["dsp_static_config"]["task_connections"]:
            src_block = conn["output_block"]
            dst_block = conn["input_block"]
            if src_block == "capture":
                src_block = (f"capture_{device_id}")
            if dst_block == "playback":
                dst_block = (f"playback_{device_id}")
            dot.edge(src_block, dst_block, style="dashed", label=f"out:{conn['output_channel']} → in:{conn['input_channel']}")
        # Draw block_connections
        for task in device["dsp_static_config"]["audio_tasks"]:
            meter_jack_conn_added = False
            for conn in task.get("block_connections", []):
                src = conn["source_block"]
                dst = conn["destination_block"]
                src_label = f"{conn['output_terminal']}:{conn['output_channel']}"
                dst_label = f"{conn['input_terminal']}:{conn['input_channel']}"
                # don't visualize all meter task internal block connections, too many channels to display
                if not src.endswith("meter_jack_in"):
                    dot.edge(src, dst, label=f"{src_label} → {dst_label}")
                elif meter_jack_conn_added == False:
                    dot.edge(src, dst, label=f"out:all → in:all")
                    meter_jack_conn_added = True
    # Draw fusion-connect streams from unified audio_streams
    fc_streams = []
    for stream in json_result.get("audio_streams", []):
        properties = stream.get("properties", {})
        if properties.get("is_fusion_connect"):
            fc_streams.append(stream)

    # Backward compatibility for older fusion-connect stream output format.
    if not fc_streams:
        for conn in json_result.get("device_connections", []):
            fc_streams.append({
                "source_device_uid": conn.get("source_device"),
                "dest_device_uid": conn.get("destination_device"),
                "properties": {
                    "source_port": conn.get("source_port"),
                }
            })

    for conn in fc_streams:
        src_dev = conn.get("source_device_uid")
        dst_dev = conn.get("dest_device_uid")
        source_port = conn.get("properties", {}).get("source_port")
        if not src_dev or not dst_dev or source_port is None:
            continue
        src_block, dst_block = get_fc_src_dst_blks(json_result, src_dev, dst_dev, source_port)
        if src_block and dst_block:
            dot.edge(src_block, dst_block, style="dotted", label=f"port {source_port}")

    # Render the diagram to file
    png_data = dot.pipe(format="png")
    # save input config visualization
    if save_image:
        with open(output_file, "wb") as f:
            f.write(png_data)
    # to base64
    base64_image = base64.b64encode(png_data).decode()
    return base64_image

def visualize_output(json_config, json_output, output_file, save_image=True):
    '''
    Given an input configuration and the corresponding output from the
    resource manager, create a block diagram using graphviz dot format, 
    decomposed among the processors in the system.

    Input
        - json_config: JSON input config (dict)
        - json_output: resource manager JSON output config (dict)
        - output_file: output image filename if to save visualization
        - save_image: save image if set, bool
    Output
        - base64_image: base64 image format of the visualization of output config
    '''
    dot_buffer = io.StringIO()

    dot_buffer.write('digraph g {\n')
    dot_buffer.write('  graph [rankdir = "LR", splines="ortho", odesep="0.7", ranksep="0.8"];\n')

    locations = []
    for json_device in json_output['result']['devices']:
        if not json_device['location'] in locations:
            locations.append(json_device['location'])

    cluster_id = 0
    for location in locations:
        dot_buffer.write('  subgraph cluster_' + str(cluster_id) + '{\n')
        cluster_id += 1
        dot_buffer.write('        color = "red" ;\n') # add color to device location
        dot_buffer.write('    label = "' + location + '";\n')

        for json_device in json_output['result']['devices']:
            if json_device['location'] != location:
                continue
            dot_buffer.write('    subgraph cluster_' + str(cluster_id) + '{\n')
            cluster_id += 1
            dot_buffer.write('        color = "blue" ;\n') # add color to device border
            dot_buffer.write('      label = "' + json_device['label'] + '";\n')
            for json_core in json_device['cores']:
                dot_buffer.write('      subgraph cluster_' + str(cluster_id) + '{\n')
                cluster_id += 1
                dot_buffer.write('        color = "black" ;\n') # add color to core border
                dot_buffer.write('        label = "' + json_core['label'] + '";\n')
                for block_id in json_core['block_ids']:
                    for json_block in json_config['blocks']:
                        if json_block['id'] != block_id:
                            continue
                        dot_buffer.write('        "' + str(json_block['id']) + '"')
                        dot_buffer.write('[ label = "' + json_block['name'] +
                                       ' (' + json_block['algorithm'] +
                                       ')" shape = "Mrecord"];\n')
                dot_buffer.write('      }\n')
            dot_buffer.write('    }\n')
        dot_buffer.write('  }\n')

    for connection in json_config['block_connections']:
        dot_buffer.write('  "' + connection["source_block"] + '" -> "' +
                        connection["destination_block"] + '";\n')

    dot_buffer.write('}\n')
    dot_string = dot_buffer.getvalue()
    dot = graphviz.Source(dot_string)
    png_data = dot.pipe(format="png")
    # save input config visualization
    if save_image:
        with open(output_file, "wb") as f:
            f.write(png_data)
    # to base64
    base64_image = base64.b64encode(png_data).decode()
    return base64_image

# if __name__ == '__main__':
#     import argparse

#     parser = argparse.ArgumentParser(prog='visuzalizer',
#                                      description='Export resource manager config and output to graphviz dot format.',
#                                      epilog='dot -Tpng -o"bar.png" "foo.dot"')
#     parser.add_argument('-c', '--configuration', default='configs/sample_config.json')
#     parser.add_argument('-o', '--output', default='outputs/sample_output.json')
#     parser.add_argument('-b', '--block_diagram', default='config.dot')
#     parser.add_argument('-d', '--decomposition', default='output.dot')
#     args = parser.parse_args()

#     visualize_config(args.configuration, args.block_diagram)
#     visualize_output(args.configuration, args.output, args.decomposition)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(prog='visuzalizer',
                                     description='Export resource manager output block diagram (.png)')
    parser.add_argument('-o', '--output', help="Path to the output configuration file")
    parser.add_argument('-f', '--filename', default="dsp_diagram_out.png", help="Output filename")

    args = parser.parse_args()

    if args.output:
        with open(args.output) as f:
            json_output = json.load(f)
        output_file = args.filename
        visualize_output_dsp(json_output, output_file, save_image=True)