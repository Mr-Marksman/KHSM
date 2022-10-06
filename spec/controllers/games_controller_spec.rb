require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  describe 'kick from #take_money' do
    before do
      put :take_money, id: game_w_questions.id
    end

    it 'not 200 status' do
      expect(response.status).not_to eq(200)
    end

    it 'right redirect' do
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'has alert' do
      expect(flash[:alert]).to be
    end
  end



  describe '#create game' do

    context 'Anon' do
      describe 'kick from #create' do
        before do
          post :create
        end

        it 'not 200 status' do
          expect(response.status).not_to eq(200)
        end

        it 'right redirect' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'has alert' do
          expect(flash[:alert]).to be
        end
      end
    end

    context 'Usual user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
      end
      before do
        generate_questions(15)
        post :create
      end

      it 'not to finish game' do
        expect(game.finished?).to be false
      end

      it 'correct user has' do
        expect(game.user).to eq(user)
      end

      it 'right redirect' do
        expect(response).to redirect_to(game_path(game))
      end

      it 'has notice' do
        expect(flash[:notice]).to be
      end
    end
  end

  describe '#show alien game' do

    context 'Usual user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
      end
      before do
        alien_game = FactoryGirl.create(:game_with_questions)
        get :show, id: alien_game.id
      end

      it 'not 200 status' do
        expect(response.status).not_to eq(200) # статус не 200 ОК
      end

      it 'right redirect' do
        expect(response).to redirect_to(root_path)
      end

      it 'has alert' do
        expect(flash[:alert]).to be # во flash должен быть прописана ошибка
      end
    end
  end

  describe '#show game' do
    context 'Anon' do
      describe 'kick from #show' do
        before do
          get :show, id: game_w_questions.id
        end

        it 'not 200 status' do
          expect(response.status).not_to eq(200)
        end

        it 'right redirect' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'has alert' do
          expect(flash[:alert]).to be
        end
      end
    end

    context 'Usual user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
      end

      before do
        get :show, id: game_w_questions.id
      end

      it 'not finish game' do
        expect(game.finished?).to be false
      end

      it 'correct user has' do
        expect(game.user).to eq(user)
      end

      it 'not 200 status' do
        expect(response.status).to eq(200)
      end

      it 'render show' do
        expect(response).to render_template('show')
      end
    end
  end

  describe 'give answer' do
    context 'Anon' do
      context'kick from #answer' do
        before do
          put :answer, id: game_w_questions.id
        end

        it 'not 200 status' do
          expect(response.status).not_to eq(200)
        end

        it 'right redirect' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'has alert' do
          expect(flash[:alert]).to be
        end
      end
    end

    context 'Usual user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
      end

      context 'answers correct' do
        before do
          put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
        end

        it 'not finish game' do
          expect(game.finished?).to be false
        end

        it 'next level' do
          expect(game.current_level).to be > 0
        end

        it 'right redirect' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'has not any flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'incorrect answer' do
        before do
          put :answer, letter: "f", id: game_w_questions.id
        end

        let(:game) { assigns(:game) }

        it 'finishes game with "fail"' do
          expect(game.finished?).to be true
          expect(game.status).to be(:fail)
        end

        it "redirect to user_path" do
          expect(response).to redirect_to(user_path(user))
        end

        it 'won prize' do
          expect(user.balance).to eq game_w_questions.prize
        end
      end

      context 'takes money' do

        before do
          game_w_questions.update_attribute(:current_level, 2)
          put :take_money, id: game_w_questions.id
        end

        it 'finishes game' do
          expect(game.finished?).to be true
        end

        it 'has first prize' do
          expect(game.prize).to eq(200)
        end

        context 'after reload' do
          before do
            user.reload
          end

          it 'balance save prize' do
            expect(user.balance).to eq(200)
          end

          it 'right redirect' do
            expect(response).to redirect_to(user_path(user))
          end

          it 'has warning' do
            expect(flash[:warning]).to be
          end
        end
      end

      it 'try to create second game' do
        expect(game_w_questions.finished?).to be false

        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game)
        expect(game).to be_nil

        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#help' do

    context 'Usual user' do
      let(:game) { assigns(:game) }

      let(:game_question) do
        FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
      end

      before do
        sign_in user
      end

      describe '.add_audience_help' do
        before do
          put :help, id: game_w_questions.id, help_type: :audience_help
        end

        it 'not finish game' do
          expect(game.finished?).to be false
        end

        it 'used a_h' do
          expect(game.audience_help_used).to be true
        end
      end

      describe '.add_fifty_fifty' do
        let(:values) { game_question.help_hash[:fifty_fifty] }

        before do
          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end

        it 'not finish game' do
          expect(game.finished?).to be false
        end

        it 'f_f used' do
          expect(game.fifty_fifty_used).to be true
        end
      end

      describe '.add_friend_call' do
        let(:value) { game_question.help_hash[:friend_call] }

        before do
          put :help, id: game_w_questions.id, help_type: :friend_call
        end

        it 'not finish game' do
          expect(game.finished?).to be false
        end

        it 'f_c used' do
          expect(game.friend_call_used).to be true
        end
      end
    end
  end
end
