import sys
import os
import re


def convert_to_camel_case(snake_str):
    components = snake_str.split("_")
    return components[0] + "".join(x.title() for x in components[1:])


def convert_proto_type(proto_type):
    type_mapping = {
        "uint64": "Long",
        "uint32": "Integer",
        "string": "String",
        "bool": "Boolean",
    }
    if proto_type.startswith("repeated"):
        inner_type = proto_type.split()[1]
        return f"List<{convert_proto_type(inner_type)}>"
    return type_mapping.get(proto_type, proto_type)


def extract_blocks(proto_file, block_type):
    with open(proto_file, "r") as f:
        lines = f.readlines()

    pattern = re.compile(rf"{block_type}\s+(\w+)\s*{{")
    end_pattern = re.compile(r"}")
    inside_block = False
    block_name = None
    blocks = []
    current_block = []

    for line in lines:
        if inside_block:
            current_block.append(line)
            if end_pattern.search(line):
                blocks.append((block_name, current_block))
                inside_block = False
                current_block = []
        else:
            match = pattern.search(line)
            if match:
                block_name = match.group(1)
                inside_block = True
                current_block.append(line)

    return blocks


def generate_java_pojo(proto_file, output_dir):
    message_blocks = extract_blocks(proto_file, "message")

    output_file = os.path.join(output_dir, "ClientDto.java")
    pojo_lines = [
        "package com.example.dto;",
        "import java.util.*;",
        "import com.fasterxml.jackson.annotation.*;",
        "import io.norberg.automatter.*;",
        "import io.norberg.automatter.jackson.*;",
        "import com.example.mapper.*;",
        "import com.example.protobuf.*;",
        "import com.example.protobuf.Client;",
    ]

    for block_name, block_lines in message_blocks:
        fields = []
        oneof_blocks = []
        enum_blocks = []
        inside_oneof = False
        inside_enum = False

        for line in block_lines:
            if inside_enum:
                enum_field_match = re.match(r"\s*(\w+)\s*=\s*\d+;", line)
                if enum_field_match:
                    enum_value = enum_field_match.group(1)
                    # enum_blocks.append(enum_value)
                if re.search(r"}", line):
                    inside_enum = False
            elif inside_oneof:
                field_match = re.match(r"\s*(\w+\s*\w*)\s+(\w+)\s*=\s*(\d+);", line)
                if field_match:
                    field_type = field_match.group(1).strip()
                    field_name = field_match.group(2)
                    oneof_blocks.append((field_type, field_name))
                if re.search(r"}", line):
                    inside_oneof = False
            else:
                if re.search(r"enum\s+\w+\s*{", line):
                    inside_enum = True
                    # enum_blocks.append(line)
                else:
                    field_match = re.match(r"\s*(\w+\s*\w*)\s+(\w+)\s*=\s*(\d+);", line)
                    if field_match:
                        field_type = field_match.group(1).strip()
                        field_name = field_match.group(2)
                        fields.append((field_type, field_name))
                    if re.search(r"oneof\s+(\w+)\s*{", line):
                        inside_oneof = True

        interface_name = block_name
        proto_class_name = f"Client.{block_name}"

        pojo_lines.append("")
        pojo_lines.append(f"@AutoMatter")
        pojo_lines.append(
            f"@ProtobufType(protobufType = {proto_class_name}.class, hierarchical = true)"
        )
        pojo_lines.append(f"interface {interface_name} {{")
        pojo_lines.append("")

        for field_type, field_name in fields:
            java_type = convert_proto_type(field_type)
            camel_case_name = convert_to_camel_case(field_name)
            pojo_lines.append(f"    @JsonProperty")
            pojo_lines.append(f"    {java_type} {camel_case_name}();")
            pojo_lines.append("")

        for field_type, field_name in oneof_blocks:
            java_type = f"Optional<{convert_proto_type(field_type)}>"
            camel_case_name = convert_to_camel_case(field_name)
            pojo_lines.append(f"    @JsonProperty")
            pojo_lines.append(f"    {java_type} {camel_case_name}();")
            pojo_lines.append("")

        if oneof_blocks:
            pojo_lines.append(f"    @JsonProperty")
            pojo_lines.append(f"    String configKey();")
            pojo_lines.append("")

        pojo_lines.append(f"    @JsonIgnore")
        pojo_lines.append(f"    default {proto_class_name} toProtobuf() {{")
        pojo_lines.append(f"        return ClientMapper.toProtobuf(this);")
        pojo_lines.append(f"    }}")
        pojo_lines.append("")
        pojo_lines.append(
            f"    static {interface_name} fromProtobuf({proto_class_name} protobuf) {{"
        )
        pojo_lines.append(
            f"        return ClientMapper.fromProtobuf(protobuf, {interface_name}.class);"
        )
        pojo_lines.append(f"    }}")
        pojo_lines.append("}")

        if enum_blocks:
            pojo_lines.extend(enum_blocks)
            pojo_lines.append("")

    with open(output_file, "w") as f:
        f.write("\n".join(pojo_lines))

    print(f"Generated {output_file}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python generate_pojo.py <path_to_proto_file> <output_directory>")
        sys.exit(1)

    proto_file = sys.argv[1]
    output_dir = sys.argv[2]

    generate_java_pojo(proto_file, output_dir)
