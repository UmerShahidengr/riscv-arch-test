import os
import fileinput

source_file         = "fnmsub_b15-base.S"           # File Name to convert
destination_dir     = "/home/user/Work/MyFiles"     # Path to save split files
FILE_NAME_FORMAT    = "fnmsub_b15-{i:03d}.S"        # Naming convention for split tests
LABEL_NAME          = "fnmsub_b15"                  # coverage label name
SIGNATURE_PER_SPLIT = 6                             # 128*SIGNATURE_PER_SPLIT tests will be split in one file
NUMBER_OF_TESTS     = 50                            # Number of tests to generate



INITIAL_PARSER      = "1-21"                            # initial few lines including comments
SIGNATURE_DEFS      = "34-35"                           # lines having RVTEST_FP_ENABLE() and SIGNATURE defs
CODE_BEGIN_WRAPPER  = "23-32"                           # Fixed Lines including RVTEST_CODE_BEGIN, RVMODEL_BOOT etc.
CODE_END_WRAPPER    = "267237-267250"                   # RVTEST_CODE_END, RVTEST_DATA_BEGIN, RVMODEL_HALT etc.
NUM_NAN_BOXED       = 128*3*SIGNATURE_PER_SPLIT         # Number of NAN_BOXED to copy
SIGNATURE_RANGE     = "381638-381671"                   # signature labels to copy
LAST_LINES          = "382840-382866"                   # last few lines including RVMODEL_DATA_END


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

with open(source_file, 'r') as f:
        lines = f.readlines()

label_indices = [i for i, line in enumerate(lines) if line.strip().startswith("RVTEST_SIGBASE(x1,signature_x1")]


# Start of loop
for i in range(1,NUMBER_OF_TESTS+1):
        destination_file = os.path.join(destination_dir, FILE_NAME_FORMAT.format(i=i))
        new_line = ""
        with open(destination_file, 'w') as destination:
                destination.write(new_line)  # Add the new line

        line_range = INITIAL_PARSER
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        new_line = "RVTEST_ISA(\"RV32IF_Zicsr,RV32IFD_Zicsr,RV64IF_Zicsr,RV64IFD_Zicsr,RV32EF_Zicsr,RV32EFD_Zicsr,RV64EF_Zicsr,RV64EFD_Zicsr\")"
        with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

        line_range = CODE_BEGIN_WRAPPER
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)


        new_line = 'RVTEST_CASE(1,\"//check ISA:=regex(.*E.*F.*);def TEST_CASE_1=True;\",{})'.format(LABEL_NAME)
        with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

        line_range = SIGNATURE_DEFS
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        SIGNATURE_INDEX = 1
        SIGNATURE_LABEL = SIGNATURE_PER_SPLIT*(i-1)

        for j in range(1,SIGNATURE_PER_SPLIT+1):
            new_line = "RVTEST_SIGBASE(x1,signature_x1_{})".format(SIGNATURE_INDEX)
            SIGNATURE_INDEX = SIGNATURE_INDEX + 1
            with open(destination_file, 'a') as destination:
                destination.write(new_line + '\n')  # Add the new line

            if SIGNATURE_LABEL<297:
                start_index = label_indices[SIGNATURE_LABEL]
                end_index = label_indices[SIGNATURE_LABEL+1]
                label = lines[start_index].strip()
                SIGNATURE_LABEL = SIGNATURE_LABEL + 1

                with open(destination_file, 'a') as file:
                    file.writelines(lines[start_index+1:end_index])

            else:
                line_range = "266446-267236"
                lines_to_copy = parse_range(line_range)
                copy_lines(source_file, destination_file, lines_to_copy)
                break

        line_range = CODE_END_WRAPPER
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        word_to_find = "NAN_BOXED"
        start_num = NUM_NAN_BOXED*(i-1)
        max_lines_to_copy = NUM_NAN_BOXED

        copy_word(source_file, destination_file, word_to_find, max_lines_to_copy, start_num)

        line_range = SIGNATURE_RANGE
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)

        line_range = LAST_LINES
        lines_to_copy = parse_range(line_range)
        copy_lines(source_file, destination_file, lines_to_copy)


    # Loop through the file, replacing 'FLEN' with 'FLEN/8'
        with fileinput.FileInput(destination_file, inplace=True) as file:
            k=0
            for line in file:
                print(line.replace('FLEN/8', '0 + 3*{}*FLEN/8'.format((k-42)//7)), end='')
                k = k + 1
        # file.write(line.replace("FLEN/8","FLEN/{}".format(i+2)))