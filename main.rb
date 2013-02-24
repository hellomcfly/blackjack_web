require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'


##################################
#### Initiate ####################
##################################
set :sessions, true

before do
	@game_over = false
end 



##################################
#### Start and End ###############
##################################
get '/' do 
	if session[:player_name].nil? 
		redirect '/set_player_names'
	else
		redirect '/betting'
	end 
end 

get '/set_player_names' do 
	erb :set_player_names
end 

get '/goodbye' do 
	session[:playername] = nil
	session[:money] = nil
	erb :goodbye
end 

post '/set_player_names' do 
	if params['name'].empty? 
		@error = "Must input a name, no matter how wonky!"
		halt erb(:set_player_names)
	else
		session[:name] = params['name']
		session[:money] = 1000
		redirect '/betting'
	end 
end 

##################################
#### Betting #####################
##################################
get '/betting' do  
	erb :betting
end 

post '/betting' do 
	if params['bet'].to_i == 0 
		@error = "Must input a positive number using only digits 0-9!"
		erb :betting
	elsif params['bet'].to_i > session[:money]
		@error = "Nice try, but you can't bet more than you have."
		erb :betting
	elsif params['bet'].to_i < 0
		@error = "Nice try, but you can't wager a negative."
		erb :betting
	else
		session[:bet] = params['bet'].to_i
		redirect '/blackjack'
	end 
end 

##################################
#### Blackjack ###################
##################################
get '/blackjack' do 

	#Make sure logged-in
	if session[:name].empty? 
		@error = "Must input a name, no matter how wonky!"
		erb :set_player_names
	end 

	#create deck
	suits = ['clubs', 'diamonds', 'spades', 'hearts']
	face_values = ['2','3','4','5','6','7','8','9','10','jack','queen','king','ace']
	session[:deck] = face_values.product(suits).shuffle

	#deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []

	2.times do 
		session[:player_cards] << session[:deck].pop
		session[:dealer_cards] << session[:deck].pop
	end 

	#Calculate player totals
	@player_total = total_calc(session[:player_cards])
	@dealer_total = total_calc(session[:dealer_cards])
	
	#direct to appropriate template
	erb :blackjack

	#Start flow of game

end 

post '/blackjack/player/hit' do 
	session[:player_cards] << session[:deck].pop
	@player_total = total_calc(session[:player_cards])
	if @player_total >= 21 
		@game_over = true
	end
	if @game_over == true 
		outcome = resolve_game(@player_total, @dealer_total)
		if outcome[0] == 1
			@success = outcome[1]
			@success
		else
			@error = outcome[1]
			@error
		end
	end 
	erb :blackjack
end

post '/blackjack/player/stand' do
	@success = "You've chosen to stand. Are you ready for the results?"
	@dealer_suspense = true
	erb :blackjack
end


post '/blackjack/dealer/conclude' do
	@dealer_total = total_calc(session[:dealer_cards])
	while @dealer_total < 17 
		session[:dealer_cards] << session[:deck].pop
		@dealer_total = total_calc(session[:dealer_cards])
	end 
	@game_over = true

	@player_total = total_calc(session[:player_cards])
	@dealer_total = total_calc(session[:dealer_cards])

	
	outcome = resolve_game(@player_total, @dealer_total)
	if outcome[0] == 1
		@success = outcome[1]
		@success
	else
		@error = outcome[1]
		@error
	end 
	erb :blackjack
end 

post '/blackjack/play_again' do
	if params['play_again'] == "Yes" 
		redirect '/betting'
	else
		redirect '/goodbye'
	end 
end

##################################
#### Helper Methods ##############
##################################
helpers do

	def total_calc(card_array)
		total = 0
		card_array.each do |card|
			case card[0]
				when "ace" then total += 11
				when "king" then total += 10
				when "queen" then total += 10
				when "jack" then total += 10
				else
					total += card[0].to_i
			end
		end

		total
	    card_array.select{|element| element[0] == "ace"}.count.times do
	      break if total <= 21
	      total -= 10
	    end
	    
		total		
	end

	def resolve_game(player_total,dealer_total)
		if player_total > 21
			session[:money] -= session[:bet]
			[0,"Sorry, you busted! You lose!"]
		elsif dealer_total > 21
			session[:money] += session[:bet]
			[1,"Dealer busted! You win!"]
		elsif player_total == dealer_total
			[1,"Tie game! Better than losing, no?"]
		elsif player_total == 21
			session[:money] += session[:bet]
			[1,"You hit blackjack! You win!"]
		elsif dealer_total == 21
			session[:money] -= session[:bet]
			[0,"Dealer hit blackjack! You lose."]
		elsif player_total > dealer_total
			session[:money] += session[:bet]
			[1,"Your score beats dealer's score. You win!"]
		elsif player_total < dealer_total
			session[:money] -= session[:bet]
			[0,"Dealer score beats your score. You lose!"]
		else
			[0,"Something happened. I can't count. Sorry."]
		end
	end

	def card_image(card)
		"<img src='/images/cards/#{card[1]}_#{card[0]}.jpg' class='img-polaroid' height='120' width='84'/>"
	end


end

