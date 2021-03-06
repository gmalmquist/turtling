#!/usr/bin/env python
# coding=utf-8
from __future__ import print_function, with_statement

import os
import re
import shutil
import sys


SAVE_PATH = '/home/g/ftb/Termina/computer'
COMPUTER_SCOPE_PATTERN = re.compile(r'^(.*?)__(\d+)$')


class Installer(object):

  def __init__(self, save_path, root, install_in_subfolders=True):
    self.save_path = save_path
    self.root = root
    self.install_in_subfolders = install_in_subfolders
  
  @property 
  def computer_folder(self):
    return self.save_path

  def computers_iter(self):
    if not self.install_in_subfolders:
      yield self.computer_folder
      return
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
        if include_path.startswith('/'):
          include_path = include_path[1:]
        else:
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
    data = ''.join(self.processed_file_lines(src))
    if os.path.exists(dst):
      with open(dst, 'r') as f:
        prev = f.read()
      if prev == data:
        print(' noop: ', end='')
        return
      print(' removing existing file... '.format(dst), end='')
      os.remove(dst)
    with open(dst, 'w') as f:
      f.write(data)

  def install_file(self, src):
    src = os.path.normpath(src)
    dst_name = os.path.basename(src)
    dst_name = dst_name[:dst_name.find('.')]
    scope_match = COMPUTER_SCOPE_PATTERN.match(dst_name)
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
      self.process_file(src, dst)
      print('Done.')

  def install(self):
    root = self.root
    for name in os.listdir(root):
      if name.endswith('.lua'):
        self.install_file(os.path.join(root, name))


if __name__ == '__main__':
  installer = Installer(SAVE_PATH, os.path.abspath('src/universal'))
  installer.install()

  args = sys.argv[1:]
  if len(args) >= 2:
    source = args[0]
    computers = args[1:]
    name = os.path.basename(source)
    if '.' in name:
      name = name[:name.rfind('.')]
    for c in computers:
      print('Install %s -> %s' % (source, c), end=' ')
      installer.process_file(os.path.abspath(source), os.path.join(SAVE_PATH, c, name))
      print('  Done.')
      

