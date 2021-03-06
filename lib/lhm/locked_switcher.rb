# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'
require 'lhm/migration'
require 'lhm/sql_helper'

module Lhm
  # Switches origin with destination table with a write lock. Use this as
  # a safe alternative to rename, which can cause slave inconsistencies:
  #
  #   http://bugs.mysql.com/bug.php?id=39675
  #
  # LockedSwitcher adopts the Facebook strategy, with the following caveat:
  #
  #   "Since alter table causes an implicit commit in innodb, innodb locks get
  #   released after the first alter table. So any transaction that sneaks in
  #   after the first alter table and before the second alter table gets
  #   a 'table not found' error. The second alter table is expected to be very
  #   fast though because copytable is not visible to other transactions and so
  #   there is no need to wait."
  #
  class LockedSwitcher
    include Command
    include SqlHelper

    attr_reader :connection

    def initialize(migration, connection = nil)
      @migration = migration
      @connection = connection
      @origin = migration.origin
      @destination = migration.destination
    end

    def statements
      uncommitted { switch }
    end

    def switch
      [
        "lock table `#{ @origin.name }` write, `#{ @destination.name }` write",
        "alter table `#{ @origin.name }` rename `#{ @migration.archive_name }`",
        "alter table `#{ @destination.name }` rename `#{ @origin.name }`",
        "commit",
        "unlock tables"
      ]
    end

    def uncommitted(&block)
      [
        "set @lhm_auto_commit = @@session.autocommit",
        "set session autocommit = 0",
        yield,
        "set session autocommit = @lhm_auto_commit"
      ].flatten
    end

    def validate
      unless table?(@origin.name) && table?(@destination.name)
        error "`#{ @origin.name }` and `#{ @destination.name }` must exist"
      end
    end

  private

    def revert
      sql "unlock tables"
    end

    def execute
      sql statements
    end
  end
end
