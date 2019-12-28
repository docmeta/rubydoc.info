#!/bin/env ruby
require_relative '../lib/gem_updater'

GemUpdater.update_remote_gems display: true
