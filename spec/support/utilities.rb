def wait_for_ajax(timeout = Capybara.default_wait_time)
  count = 0
  while page.evaluate_script("$.active").to_i > 0
    count += 1
    sleep timeout
    break if count == 10
  end
end

def sign_in(admin_user)
  visit root_path
  fill_in 'Username', with: admin_user.email
  fill_in 'Password', with: admin_user.password
  click_button 'Login'
end

def hover(element)
  case Capybara.current_driver.to_s
  when 'webkit' then element.trigger(:mouseover)
  when 'selenium' then element.hover
  end
end

def within_timeout(timeout = Capybara.default_wait_time)
  default = Capybara.default_wait_time
  Capybara.default_wait_time = timeout
  yield
  Capybara.default_wait_time = default
end
