require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'


set :sessions, true

###############################
get '/' do
	if session[:player_name].nil?
		redirect '/set_player_names'
	else
		redirect '/game'
	end
end

###############################
get '/set_player_names' do
	erb :set_player_names
end

get '/goodbye' do
	erb :goodbye
end

post '/set_player_names' do
	puts params['name']
	if params['name'].empty?
		@error = "Must input a name, no matter how wonky!"
		erb :set_player_names
	else
		session[:name] = params['name']
		redirect '/game'
	end
end

###############################
get '/game' do

	#Make sure logged-in
	if session[:name].empty?
		@error = "Must input a name, no matter how wonky!"
		erb :set_player_names
	end

	#create deck
	suits = [' of Hearts', ' of Diamonds', ' of Spades', ' of Clubs']
	face_values = ['2','3','4','5','6','7','8','9','10','Jack','Queen','King','Ace']
	session[:deck] = face_values.product(suits).shuffle

	#deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []
	2.times do
		session[:player_cards] << session[:deck].pop
		session[:dealer_cards] << session[:deck].pop
	end

	@player_total = total_calc(session[:player_cards])
	@dealer_total = total_calc(session[:dealer_cards])
	#direct to appropriate template
	erb :blackjack

	#Start flow of game

end

post '/game' do
	if params['choice'] == "Hit"
		session[:player_cards] << session[:deck].pop
		@player_total = total_calc(session[:player_cards])
		if @player_total > 21
			@game_over = true
		end
	elsif params['choice'] == "Stand"
		@dealer_total = total_calc(session[:dealer_cards])
		while @dealer_total < 17
			session[:dealer_cards] << session[:deck].pop
			@dealer_total = total_calc(session[:dealer_cards])
		end
		@game_over = true
	elsif params['play_again'] == "Yes"
		redirect '/game'
	else
		redirect '/goodbye'
	end
	
	@player_total = total_calc(session[:player_cards])
	@dealer_total = total_calc(session[:dealer_cards])

	if @game_over == true
		@outcome = resolve_game(@player_total, @dealer_total)
	end
	erb :blackjack
end


###############################
helpers do

	def total_calc(card_array)
		total = 0
		card_array.each do |card|
			case card[0]
				when "Ace" then total += 11
				when "King" then total += 10
				when "Queen" then total += 10
				when "Jack" then total += 10
				else
					total += card[0].to_i
			end
		end
		if total > 21 && has_ace(card_array)
			total -=10
		end
		total		
	end

	def resolve_game(player_total,dealer_total)
		if player_total > 21
			"Sorry, you busted! You lose!"
		elsif dealer_total > 21
			"Dealer busted! You win!"
		elsif player_total == dealer_total
			"Tie game! Better than losing, no?"
		elsif player_total > dealer_total
			"Your score beats dealer's score. You win!"
		elsif player_total < dealer_total
			"Dealer score beats your score. You lose!"
		else
			"Something happened. I can't count. Sorry."
		end
	end

	def has_ace(card_array)
		card_array[0].each.include? "Ace"
	end

end

