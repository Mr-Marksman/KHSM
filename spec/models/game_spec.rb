# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
          )
        )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      # берем игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '.current_game_question' do
    it 'returns question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end
  end

  describe '#previous_level ' do
    it 'returns previous level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  describe '#answer_current_question!' do
    context 'correct answer got' do
      before(:each) do
        game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
      end

      context 'not final question' do
        let!(:game_w_questions) { FactoryGirl.create(:game_with_questions, current_level: 1) }

        it 'next level' do
          expect(game_w_questions.current_level).to eq(2)
        end

        it 'game "in_progress"' do
          expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'final question' do
        let!(:game_w_questions) { FactoryGirl.create(:game_with_questions, current_level: Question::QUESTION_LEVELS.max) }

        it 'final prize' do
          expect(game_w_questions.prize).to eq(1000000)
        end

        it 'game won' do
          expect(game_w_questions.status).to eq(:won)
        end
      end


      context "time out" do
        before(:each) do
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
          game_w_questions.created_at = 10.hours.ago
        end

        let!(:answered_game) do
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
          game_w_questions
        end

        it '"finished?" = true' do
          expect(answered_game.finished?).to be(true)
        end

        it '"timeout"' do
          expect(answered_game.status).to eq(:timeout)
        end
      end
    end

    context 'wrong answer' do
      let!(:incorrect_answer_key) { ['a', 'b', 'c', 'd'].
        reject { |letter| letter == game_w_questions.current_game_question.correct_answer_key }.sample }

        before(:each) do
          game_w_questions.answer_current_question!(incorrect_answer_key)
        end

        it 'finishes game' do
          expect(game_w_questions.finished?).to be true
        end

        it '"fail"' do
          expect(game_w_questions.status).to eq :fail
        end
      end
    end


  describe '.use_help' do
    context 'a_h' do
      it 'recieve add_audience_help' do
        expect(game_w_questions.current_game_question).to receive(:add_audience_help)
        game_w_questions.use_help(:audience_help)
      end
    end

    context 'f_f' do
      it 'recieve add_fifty_fifty' do
        expect(game_w_questions.current_game_question).to receive(:add_fifty_fifty)
        game_w_questions.use_help(:fifty_fifty)
      end
    end

    context 'f_c' do
      it 'recieve add_friend_call' do
        expect(game_w_questions.current_game_question).to receive(:add_friend_call)
        game_w_questions.use_help(:friend_call)
      end
    end
  end
end
