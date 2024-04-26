import os
import fileinput

def parse_range(line_range):
    ranges = line_range.split(',')
    lines_to_copy = set()
    for r in ranges:
        parts = r.split('-')
        if len(parts) == 1:
            lines_to_copy.add(int(parts[0]))
        elif len(parts) == 2:
            start, end = map(int, parts)
            lines_to_copy.update(range(start, end + 1))
        else:
            raise ValueError("Invalid range format: {}".format(r))
    return lines_to_copy

def copy_lines(source_file, destination_file, lines_to_copy):
    with open(source_file, 'r') as source:
        with open(destination_file, 'a') as destination:
            for line_number, line in enumerate(source, start=1):
                if line_number in lines_to_copy:
                    destination.write(line)

def copy_word(source_file, destination_file, word, max_lines, start_num):
    lines_copied = 0
    word_count = 0
    with open(source_file, 'r') as source:
        with open(destination_file, 'a') as destination:
            for line in source:
                if word in line:
                    word_count += 1
                if word in line and word_count > start_num:
                        destination.write(line)
                        lines_copied += 1
                if lines_copied >= max_lines:
                        break

source_file = "fnmsub_b1-base.S"
with open(source_file, 'r') as f:
        lines = f.readlines()

label_indices = [i for i, line in enumerate(lines) if line.strip().startswith("RVTEST_SIGBASE(x1,signature_x1")]


destination_directory = "/home/user/Work/MyFiles"
# Start of loop
for i in range(1,299):
        destination_file = os.path.join(destination_directory, f"fnmsub_b1-{i:02d}.S")
        new_line = ""
        with open(destination_file, 'w') as destination:
                destination.write(new_line)  # Add the new line

        line_range = "1-21"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        new_line = "RVTEST_ISA(\"RV32IF_Zicsr,RV32IFD_Zicsr,RV64IF_Zicsr,RV64IFD_Zicsr,RV32EF_Zicsr,RV32EFD_Zicsr,RV64EF_Zicsr,RV64EFD_Zicsr\")"
        with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

        line_range = "23-32"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)


        new_line = "RVTEST_CASE(1,\"//check ISA:=regex(.*E.*F.*);def TEST_CASE_1=True;\",fnmsub_b15)"
        with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

        line_range = "34-35"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        new_line = "RVTEST_SIGBASE(x1,signature_x1_1)"
        with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

        if i<298:
            start_index = label_indices[i - 1]
            end_index = label_indices[i]
            label = lines[start_index].strip()

            with open(destination_file, 'a') as file:
                file.writelines(lines[start_index+1:end_index])

        else:
            line_range = "266446-267236"
            lines_to_copy = parse_range(line_range)
            copy_lines(source_file, destination_file, lines_to_copy)

        line_range = "267237-267250"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        word_to_find = "NAN_BOXED"
        start_num = 128*3*(i-1)
        max_lines_to_copy = 128*3

        copy_word(source_file, destination_file, word_to_find, max_lines_to_copy, start_num)

        line_range = "381638-381652"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        line_range = "382840-382866"
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)


    # Loop through the file, replacing 'FLEN' with 'FLEN/8'
        with fileinput.FileInput(destination_file, inplace=True) as file:
            for line in file:
                print(line.replace('FLEN/8', '0 + 3*{}*FLEN/8'.format(i-1)), end='')
        # file.write(line.replace("FLEN/8","FLEN/{}".format(i+2)))