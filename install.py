# coding=utf-8
from __future__ import print_function, with_statement

import os
import shutil


SAVE_PATH = 'C:\\Finicky\\FTB\\FTBInfinity\\minecraft\\saves\\Termina'


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

  def install_file(self, src):
    src = os.path.normpath(src)
    dst_name = os.path.basename(src)
    dst_name = dst_name[:dst_name.find('.')]
    for folder in self.computers_iter():
      dst = os.path.normpath(os.path.join(folder, dst_name))
      hr_rel_dst = os.path.relpath(dst, self.computer_folder)
      print('Installing {} -> {} ... '.format(os.path.basename(src), hr_rel_dst), end='')
      if os.path.exists(dst):
        print(' removing existing file... '.format(dst), end='')
        os.remove(dst)
      shutil.copyfile(src, dst)
      print('Done.')

  def install(self):
    root = os.path.abspath('src')
    for name in os.listdir(root):
      self.install_file(os.path.join(root, name))


if __name__ == '__main__':
  installer = Installer(SAVE_PATH)
  installer.install()
