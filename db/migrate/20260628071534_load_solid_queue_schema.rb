# frozen_string_literal: true

class LoadSolidQueueSchema < ActiveRecord::Migration[8.1]
  TABLES = %w[
    solid_queue_blocked_executions solid_queue_claimed_executions
    solid_queue_failed_executions solid_queue_jobs solid_queue_pauses
    solid_queue_processes solid_queue_ready_executions
    solid_queue_recurring_executions solid_queue_recurring_tasks
    solid_queue_scheduled_executions solid_queue_semaphores
  ].freeze

  def up
    return if TABLES.all? { |t| connection.table_exists?(t) }

    load Rails.root.join("db/queue_schema.rb").to_s
  end

  def down
    TABLES.each { |t| drop_table(t.to_sym, if_exists: true) }
  end
end
