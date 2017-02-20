#!/usr/bin/env python
# coding=utf-8
from __future__ import print_function, with_statement

import os
import re
import shutil


SAVE_PATH = 'C:\\Finicky\\FTB\\FTBInfinity\\minecraft\\saves\\Termina'
COMPUTER_SCOPE_PATTERN = re.compile(r'^(.*?)__(\d+).lua$')


class Installer(object):

  def __init__(self, save_path):
    self.save_path = save_path
  
  @property 
  def computer_folder(self):
    return os.path.join(self.save_path, 'computer')

  def computers_iter(self):
    for name in os.listdir(self.computer_folder):
      path = os.path.join(self.computer_folder, name)
      if os.path.isdir(path):
        yield path

  def processed_file_lines(self, src, processed=None):
    if processed is None:
      processed = set()
    processed.add(src)
    include_prefix = '#include '
    with open(src, 'r') as f:
      yield '\n-- begin {} --\n'.format(os.path.basename(src))
      for line in f:
        if not line.strip().startswith(include_prefix):
          yield line 
          continue
        include_path = line.strip()[len(include_prefix):].strip()
        include_path = os.path.join(os.path.dirname(src), include_path)
        if not os.path.exists(include_path):
          print('Error {}: Include not found: {}.'.format(src, include_path))
        if include_path in processed:
          yield '\n-- already included {} --\n'.format(os.path.basename(include_path))
          continue
        for line in self.processed_file_lines(include_path, processed):
          yield line
        yield '\n-- continue {} --\n'.format(os.path.basename(src))
      yield '\n-- end {} --\n'.format(os.path.basename(src))
      yield '\n'

  def process_file(self, src, dst):
    with open(dst, 'w') as f:
      f.write(''.join(self.processed_file_lines(src)))

  def install_file(self, src):
    src = os.path.normpath(src)
    dst_name = os.path.basename(src)
    dst_name = dst_name[:dst_name.find('.')]
    scope_match = COMPUTER_SCOPE_PATTERN.match(src)
    scope_target = None
    if scope_match:
      dst_name = scope_match.group(1)
      scope_target = scope_match.group(2)
    for folder in self.computers_iter():
      if scope_match and scope_target != os.path.basename(folder):
        continue
      dst = os.path.normpath(os.path.join(folder, dst_name))
      hr_rel_dst = os.path.relpath(dst, self.computer_folder)
      print('Installing {} -> {} ... '.format(os.path.basename(src), hr_rel_dst), end='')
      if os.path.exists(dst):
        print(' removing existing file... '.format(dst), end='')
        os.remove(dst)
      self.process_file(src, dst)
      print('Done.')

  def install(self):
    root = os.path.abspath('src')
    for name in os.listdir(root):
      self.install_file(os.path.join(root, name))


if __name__ == '__main__':
  installer = Installer(SAVE_PATH)
  installer.install()
