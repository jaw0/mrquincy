# -*- mode: ruby; coding: utf-8 -*-
# Copyright (c) 2019
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2019-Aug-06 21:15 (EDT)
# Function: Mr Quincy end-user task runtime

require 'json'

module MrQuincy

  class Runtime

    def initialize(conf, init)
      @conf = conf
      @init = init
      @stdat = IO.new 3, "w"     # mrquincy expects m/r data on fd#3
      @stdat.sync  = true
      $stdout.sync = true
    end

    def config(key)
      @conf[key]
    end

    def initvalue
      @init
    end

    def filter(data)
      return if data[:time] < conf[:start]
      return if data[:time] >= conf[:end]
      return true
    end

    def progress
      @stdat.write "\n" # mapio will drop the empty record
    end

    def output(*args)
      @stdat.puts args.to_json
    end

    def print(*args)
      print args.join(' ')
    end

  end

  class Iter
    def initialize(io)
      @io = io
    end

    def each_key
      each_row { |data|
        @key = data[0]
        @curr = data
        yield @key

        # drain remaining values
        each {}

        if @next
          # reached end of values. next is next key
          @curr, @next = @next, nil
          next
        end
      }
    end

    def each
      return if @next # already read all data
      each_row { |data|
        if data[0] != @key
          @next = data
          return
        end
        yield data
      }
    end

    def count
      i = 0
      each { i += 1 }
      return i
    end

    ################
    private

    def each_row
      curr, @curr = @curr, nil
      yield curr if curr

      @io.read { |line|
        data = JSON.parse line, {symbolize_names: true}
        yield data
      }
    end

  end


end
