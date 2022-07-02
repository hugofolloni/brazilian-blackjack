defmodule Blackjack do
  def sit do
    fichas = 72
    IO.puts "Hey, bem-vindo ao 21! Você tem #{fichas} fichas."
    resposta = IO.gets "Você quer jogar? (y/n)\n  "
    resposta = String.trim_trailing(resposta) |> String.downcase
    case resposta do
      _ when resposta == "y" or resposta == "yes" ->
        deck = Deck.create_deck |> Deck.shuffle_deck
        Blackjack.apostar(deck, fichas)
      _ when resposta == "n" or resposta == "no" ->
        IO.puts "Obrigado por jogar!"
      _ ->
        IO.puts "Não entendi! Vamos tentar de novo..."
        Blackjack.sit()
    end
  end

  def apostar(deck, fichas) do
    response = IO.gets "\nO quanto você vai apostar?\n  "
    aposta = String.trim_trailing(response) |> String.to_integer
    case aposta do
      _ when aposta > fichas ->
        IO.puts "Você não tem fichas suficientes para apostar esse valor!"
        Blackjack.apostar(deck, fichas)
      _ when aposta <= 0 ->
        IO.puts "Você não pode apostar zero ou menos!"
        Blackjack.apostar(deck, fichas)
      _ ->
        IO.puts "Você apostou #{aposta} fichas."
        Blackjack.jogar(deck, fichas, aposta)
    end
  end

  def jogar(deck, fichas, aposta) do
    [player_hand, deck] = Deck.deal_two(deck)
    [dealer_hand, deck] = Deck.deal_two(deck)

    Blackjack.cartas(deck, player_hand, dealer_hand, aposta, fichas)
  end

  def cartas(deck, player_hand, dealer_hand, aposta, fichas) do
    IO.puts "\nA sua mão é: "
    for card <- player_hand do
      IO.puts "#{elem(card, 0)} #{elem(card, 1)}"
    end
    valor_mao = Hand.sum_value(player_hand, 0)
    IO.puts "O valor da sua mão é: #{valor_mao}"
    case valor_mao do
      _ when valor_mao > 21 ->
        IO.puts "\n####### Você passou! ####\n"
        fichas = fichas - aposta
        Blackjack.fim(fichas, deck)
      _ ->
        Blackjack.decisao(deck, player_hand, dealer_hand, aposta, fichas)
    end
  end

  def decisao(deck, player_hand, dealer_hand, aposta, fichas) do
    decision = IO.gets "\nVocê quer continuar? (y/n)\n  "
    decision = String.trim_trailing(decision) |> String.downcase

    case decision do
      _ when decision == "y" or decision == "yes" ->
        Blackjack.ficar(deck, player_hand, dealer_hand, aposta, fichas)
        _ when decision == "n" or decision == "no" ->
        Blackjack.sair(deck, player_hand, dealer_hand, aposta, fichas)
      _ ->
        IO.puts "Não entendi! Vamos tentar de novo..."
        Blackjack.decisao(deck, player_hand, dealer_hand, aposta, fichas)
    end
  end

  def ficar(deck, player_hand, dealer_hand, aposta, fichas) do
    [nova_carta, deck] = Deck.deal_card(deck)
    player_hand = player_hand ++ [nova_carta]
    Blackjack.cartas(deck, player_hand, dealer_hand, aposta, fichas)
  end

  def house_ficar(deck, player_hand, dealer_hand, aposta, fichas) do
    [nova_carta, deck] = Deck.deal_card(deck)
    dealer_hand = dealer_hand ++ [nova_carta]
    Blackjack.sair(deck, player_hand, dealer_hand, aposta, fichas)
  end

  def sair(deck, player_hand, dealer_hand, aposta, fichas) do
    IO.puts "\nA mão do dealer é: "
    for card <- dealer_hand do
      IO.puts "#{elem(card, 0)} #{elem(card, 1)}"
    end
    valor_mao = Hand.sum_value(player_hand, 0)
    valor_dealer = Hand.sum_value(dealer_hand, 0)
    IO.puts "O valor da mão do dealer é: #{valor_dealer}"

    case valor_dealer do
      valor_dealer when valor_dealer > 21 ->
        IO.puts "\n#### O DEALER PASSOU!! VOCÊ GANHOU!! ####\n"
        fichas = fichas + aposta
        Blackjack.fim(fichas, deck)
        valor_dealer when valor_dealer > valor_mao and valor_dealer > 16 or valor_dealer == valor_mao and valor_dealer > 16 ->
        IO.puts "\n#### O dealer ganhou! ####\n"
        fichas = fichas - aposta
        Blackjack.fim(fichas, deck)
      valor_dealer when valor_dealer < valor_mao and valor_dealer > 16 ->
        IO.puts "\n#### VOCÊ GANHOU!! ####\n"
        fichas = fichas + aposta
        Blackjack.fim(fichas, deck)
      _ ->
        IO.gets "\nAperte Enter para ver a próxima carta do dealer..."
        Blackjack.house_ficar(deck, player_hand, dealer_hand, aposta, fichas)
      end
  end


  def fim(fichas, deck) do
    if fichas > 0 do
      Blackjack.again(deck, fichas)
    else
      IO.puts "Você não tem fichas suficientes para jogar!"
      IO.puts "\nObrigado por jogar!"
      pid = spawn(fn -> 1 + 2 end)
      Process.exit(pid, :kill)
    end
  end

  def again(deck, fichas) do
    IO.puts "\nVocê tem #{fichas} fichas.\n"
    decision = IO.gets "Você quer jogar de novo? (y/n)\n  "
    decision = String.trim_trailing(decision) |> String.downcase
    case decision do
      _ when decision == "y" or decision == "yes" ->
        Blackjack.apostar(deck, fichas)
      _ when decision == "n" or decision == "no" ->
        IO.puts "\nObrigado por jogar!"
        pid = spawn(fn -> 1 + 2 end)
        Process.exit(pid, :kill)
      _ ->
        IO.puts "Não entendi! Vamos tentar de novo..."
        Blackjack.again(deck, fichas)
    end
  end

end

defmodule Deck do
  @naipes ["♥", "♦", "♣", "♠"]
  @valores ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]

  def create_deck do
    for v <- @valores, n <- @naipes, do: { v, n }
  end

  def shuffle_deck(deck) do
    Enum.shuffle(deck)
  end

  def deal_card([card | deck]) do
    [card, deck]
  end

  def deal_two(deck) do
    [card1, deck] = deal_card(deck)
    [card2, deck] = deal_card(deck)
    [[card1, card2], deck]
  end
end

defmodule Hand do
  def is_face({value, _}) do
    value == "J" or value == "Q" or value == "K"
  end

  def sum_value([], acc) do
    acc
  end

  def sum_value([head | tail], acc) do
    face = is_face(head)
    case head do
      {"A", _} when acc > 10 ->
        sum_value(tail, 1 + acc)
      {"A", _} when acc <= 10 ->
        sum_value(tail, 11 + acc)
      _ when face ->
        sum_value(tail, 10 + acc)
      _ ->
        sum_value(tail, String.to_integer(elem(head, 0)) + acc)
    end
  end
end

Blackjack.sit()
