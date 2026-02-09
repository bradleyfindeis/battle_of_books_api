# frozen_string_literal: true

module AdminPanel
  class QuizQuestionsController < BaseController
    before_action :set_book_list
    before_action :set_quiz_question, only: [:update, :destroy]

    def index
      questions = @book_list.quiz_questions.includes(:correct_book_list_item).order(:position)
      data = questions.map do |q|
        {
          id: q.id,
          question_text: q.question_text,
          position: q.position,
          correct_book_list_item_id: q.correct_book_list_item_id,
          correct_book_list_item: BookListItemSerializer.new(q.correct_book_list_item).as_json
        }
      end
      render json: data
    end

    def create
      question = @book_list.quiz_questions.build(quiz_question_params)
      question.position = (@book_list.quiz_questions.maximum(:position) || -1) + 1
      if question.save
        render json: quiz_question_json(question), status: :created
      else
        render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @quiz_question.update(quiz_question_params)
        render json: quiz_question_json(@quiz_question)
      else
        render json: { errors: @quiz_question.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @quiz_question.destroy
      head :no_content
    end

    private

    def set_book_list
      @book_list = BookList.find(params[:book_list_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Book list not found' }, status: :not_found
    end

    def set_quiz_question
      @quiz_question = @book_list.quiz_questions.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Quiz question not found' }, status: :not_found
    end

    def quiz_question_params
      params.permit(:question_text, :correct_book_list_item_id)
    end

    def quiz_question_json(q)
      {
        id: q.id,
        question_text: q.question_text,
        position: q.position,
        correct_book_list_item_id: q.correct_book_list_item_id,
        correct_book_list_item: BookListItemSerializer.new(q.correct_book_list_item).as_json
      }
    end
  end
end
