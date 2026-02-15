class CreateDailyQuestionAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_question_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.date :answer_date, null: false
      t.references :quiz_question, null: false, foreign_key: true
      t.references :chosen_book_list_item, null: false, foreign_key: { to_table: :book_list_items }
      t.boolean :correct, null: false, default: false
      t.timestamps
    end

    add_index :daily_question_answers, [:user_id, :answer_date], unique: true
  end
end
