# frozen_string_literal: true

# == Schema Information
#
# Table name: audit.logs
#
#  id            :bigint           not null, primary key
#  actor         :string(255)
#  application   :string(255)
#  diff          :jsonb
#  entrypoint    :string(255)
#  op            :enum             not null
#  table_name    :string           not null
#  table_oid     :oid              not null
#  table_schema  :string           not null
#  ts            :timestamptz      not null
#  old_record_id :text
#  record_id     :text
#  trace_id      :string(255)
#
# Indexes
#
#  ix_logs_actor                         (actor)
#  ix_logs_entrypoint                    (entrypoint)
#  ix_logs_op                            (op)
#  ix_logs_table_name_and_old_record_id  (table_name,old_record_id)
#  ix_logs_table_name_and_record_id      (table_name,record_id)
#  ix_logs_ts                            (ts)
#
module Auditing
  class Log < ActiveRecord::Base
    Op = Enum.define(
      "insert" => "INSERT",
      "update" => "UPDATE",
      "delete" => "DELETE",
      "truncate" => "TRUNCATE"
    )

    self.table_name = "audit.logs"

    enum :op, Op.members, suffix: true
  end
end
