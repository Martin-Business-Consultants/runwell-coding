# Runwell 5.17 dropped the requests table, but an install that had Code before then keeps
# coding_issues.request_id's foreign key to it. SQLite allows that until the table is rebuilt (an
# added reference, a renamed column), when copying the rows back fails: "no such table:
# main.requests". This drops every foreign key on Code's tables that points at a table that's gone,
# before the migrations that rebuild them. The columns and their values stay. Dated before them so
# it runs first where they haven't run; elsewhere it finds nothing to drop.
class DropDanglingCodingForeignKeys < ActiveRecord::Migration[8.1]
  def up
    tables.grep(/\Acoding_/).each do |table|
      foreign_keys(table).reject { table_exists?(it.to_table) }.each do |key|
        remove_foreign_key table, column: key.column
      end
    end
  end

  def down
  end
end
