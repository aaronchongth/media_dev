#!/usr/bin/env python3

import os
import shutil
import ffmpeg
import argparse
import subprocess


# Init parser
parser = argparse.ArgumentParser(
    prog='trim_and_concat',
    description='Script to trim multiple parts of videos and concatenate them '
        'together into an output video')
parser.add_argument('--input', '-i', type=str, required=True)
parser.add_argument('--stamps', '-s', type=str, required=True)
parser.add_argument('--output', '-o', type=str, required=True)


def splice(file_name, start_time, end_time, output_name):
    ffmpeg.input(
        file_name, ss=start_time, to=end_time).output(output_name).run()


def write_to_index_file(index_file, line):
    with open(index_file, 'a') as f:
        f.write(line)


def concat(index_file, output_file):
    cmd = f'ffmpeg -f concat -safe 0 -i {index_file} -c copy {output_file}'
    result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True, shell=True)


def trim_and_concat(input_file, stamps_file, output_file):
    # create tmp project folder
    project_name = input_file.split('.')[0]
    project_dir = os.path.join('/tmp', project_name)
    if os.path.exists(project_dir):
        shutil.rmtree(project_dir)
    os.mkdir(project_dir)
    
    # create indexing file
    index_file = os.path.join(project_dir, 'index.txt')
    open(index_file, 'w+').close()

    # read stamps_file
    reader = open(stamps_file, 'r')
    stamp_lines = reader.readlines()
    for i in range(len(stamp_lines)):
        if stamp_lines[i] == '\n':
            break 

        stamps = stamp_lines[i][:-1].split(' ')
        if len(stamps) != 2:
            print('Error: each stamp line must have a start time and end time '
                'only')
        start_time = stamps[0]
        end_time = stamps[1]

        snippet_name = '0' * (4 - len(str(i))) + '{}.mp4'.format(i)
        snippet_path = os.path.join(project_dir, snippet_name)

        splice(input_file, start_time, end_time, snippet_path)

        assert os.path.exists(snippet_path)
        write_to_index_file(index_file, 'file {}\n'.format(snippet_path)) 

    # concatenate
    concat(index_file, output_file)

    # clean up
    shutil.rmtree(project_dir)


def main():
    args = parser.parse_args()
    input_file = args.input
    stamps_file = args.stamps
    output_file = args.output

    assert os.path.exists(input_file)
    assert not os.path.exists(output_file)

    trim_and_concat(input_file, stamps_file, output_file)


if __name__ == '__main__':
    main()
