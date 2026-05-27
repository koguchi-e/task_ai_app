class CreateTaskLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :task_logs do |t|
      t.text :situation
      t.text :problem
      t.text :goal
      t.text :result

      t.timestamps
    end
  end
end
