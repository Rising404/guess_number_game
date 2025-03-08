#!/bin/bash

# 设置 PSQL 命令
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# 生成随机数
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# 获取用户名
echo "Enter your username:"
read USERNAME

# 检查用户是否存在
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username = '$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # 新用户
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users (username) VALUES ('$USERNAME')" > /dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME=0
else
  # 老用户
  IFS='|' read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# 开始游戏
GUESS_COUNT=0
echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS

  # 检查输入是否为整数
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  GUESS_COUNT=$((GUESS_COUNT + 1))

  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    # 猜对了
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    # 更新用户数据
    GAMES_PLAYED=$((GAMES_PLAYED + 1))
    if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]; then
      BEST_GAME=$GUESS_COUNT
    fi

    $PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID" > /dev/null
    $PSQL "INSERT INTO games (user_id, secret_number, guesses) VALUES ($USER_ID, $SECRET_NUMBER, $GUESS_COUNT)" > /dev/null

    break
  fi
done
