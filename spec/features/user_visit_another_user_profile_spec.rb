require 'rails_helper'

RSpec.feature "USER views someone else's profile", type: :feature do
  let(:user) { FactoryGirl.create :user, name: 'Max' }
  let(:another_user) { FactoryGirl.create :user, name: 'Not_Max' }

  let!(:game) do
    FactoryGirl.create(:game,
      user: another_user,
      current_level: 10,
      prize: 1000,
      created_at: Time.parse('2022.09.28, 20:40')
      )
  end

  scenario 'successfully' do
    login_as user

    visit '/'

    click_link another_user.name

    #'show page elements'
    #'show another_user name'
    expect(page).to have_content another_user.name

    #'show game status'
    expect(page).to have_content 'в процессе'

    #'show level'
    expect(page).to have_content '10'

    #'show prize'
    expect(page).to have_content '1 000 ₽'

    #'show created_at time in right format'
    expect(page).to have_content '28 сент., 20:40'

    #"don't show edit link"
    expect(page).not_to have_content 'Сменить имя и пароль'
  end
end
