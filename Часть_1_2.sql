/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Парамонов Алексей Валерьевич
 * Дата: 31.01.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков
--
-- 1.1. Доля платящих пользователей по всем данным:
--
SELECT 
	count(*) AS count_user,
	sum(payer) AS count_payer_user,
	round(sum(payer)::NUMERIC/count(*), 4) AS dolya_payer_user
FROM fantasy.users u;
--Решение:
--+-----------+-----------------+-----------------+
--| count_user| count_payer_user| dolya_payer_user|
--+-----------+-----------------+-----------------+
--|      22214|             3929|           0.1769|
--+-----------+-----------------+-----------------+
--
-- Вывод: Исходя из представленных данных в игре "Секреты Темнолесье" зарегистрировано 22214 игроков, в том числе платящих игроков 3929. Доля платящих игроков составляет составляет 17.69% 
--
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь

SELECT 
	race,
	count_payer_user,
	count_user,
	round(count_payer_user::NUMERIC/count_user, 4) AS dolya_payer_user
FROM (SELECT DISTINCT 
	r.race,
	sum(u.payer) OVER (PARTITION BY r.race) AS count_payer_user,
	count(*) OVER (PARTITION BY r.race) AS count_user
FROM fantasy.users u 
JOIN fantasy.race r ON u.race_id =r.race_id) AS q 
ORDER BY count_payer_user DESC;
--Решение:
--+---------+----------------+----------+----------------+
--| race    |count_payer_user|count_user|dolya_payer_user|
--+---------+----------------+----------+----------------+
--| Human   |            1114|      6328|          0.1760|
--| Hobbit  |             659|      3648|          0.1806|
--| Orc     |             636|      3619|          0.1757|
--| Northman|             626|      3562|          0.1757|
--| Elf     |             427|      2501|          0.1707|
--| Demon   |             238|      1229|          0.1937|
--| Angel   |             229|      1327|          0.1726|
--+---------+----------------+----------+----------------+
--
-- Вывод: В игре "Секреты Темнолесье" для персонажа существует 7 рас.
-- Пользователи выбирают больше всего персонажей расы Human (6328), ближайшие расы Yjbbit, Orc и Northman пользователи выбрали почти в два раза меньше.
-- Самое меньшее количество выбрало расу Demon 1229 игроков, но у данной расы большая доля платящих игроков и составляет 19.37%.
-- Так же можно обратить внимание, что доля платящих игроков практически одинаковая у всех рас и составляет от 17.07% до 19.37%.

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT 
	count(*) AS count_amount,
	sum(e.amount) AS sum_amount,
	min(e.amount) AS min_amount,
	max(e.amount) AS max_amount,
	round(avg(e.amount)::NUMERIC, 2) AS avg_amount,
	round(percentile_cont(0.50) WITHIN GROUP (ORDER BY e.amount)::NUMERIC, 2) AS median_amount,
	round(stddev(e.amount)::NUMERIC, 2) AS stand_dev_amount 
FROM fantasy.events e;
--Решение:
--| count_amount|sum_amount|min_amount|max_amount|avg_amount|median_amount|stand_dev_amount|
--+-------------+----------+----------+----------+----------+-------------+----------------+
--|      1307678| 686615040|       0.0|  486615.1|    525.69|        74.86|         2517.35|
--+-------------+----------+----------+----------+----------+-------------+----------------+
-- Выводы: Было совершено 1307678 внутриигровых покупок на общую стоимость 686615040. Стоимость минимальная покупки составила 0.0, а максимальная 486615.1. 
-- Средняя стоимость и медиана различаются, они составляют 525.69 и 74.86 соответственно. Разброс данных по стоимости составил 2517.35

-- 2.2: Аномальные нулевые покупки:
-- 
WITH cte AS ( -- в cte считает количество аномальних нулевых покупок и абсолютное количество покупок 
SELECT
	count(*) AS count_amount_nol,
	(SELECT count(*) FROM fantasy.events e2) AS count_amount_all
FROM fantasy.events e 
WHERE amount = 0
) -- в основном запросе считаем долю аномальным нулевых покупок от общего числа покупок
SELECT 
	count_amount_nol,
	count_amount_all,
	round(count_amount_nol::NUMERIC/count_amount_all, 4) AS dolya_amount_nol
FROM cte;
--Решение:
--+-----------------+----------------+----------------+
--| count_amount_nol|count_amount_all|dolya_amount_nol|
--+-----------------+----------------+----------------+
--|              907|         1307678|          0.0007|
--+-----------------+----------------+----------------+
-- Вывод: В игре "Секреты Темнолесье" присутствуют аномальные нулевые покупки в количестве 907, что составляет 0.07% от абсолютного количества покупок.

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
--
SELECT
-- для информативности присваиваем текстовые значения к платящим/неплатящим игрокам 
	CASE 
		WHEN payer = 1
		THEN 'платящий'
		WHEN payer = 0
		THEN 'неплатящий'
	END AS group_user,
-- считаем общее количество платящего/неплатящего игрока
	count(DISTINCT u.id) AS count_user, 
-- считаем среднее количество покупок на одного платящего/неплатящего игрока
	count(e.transaction_id)/count(DISTINCT u.id) AS avg_count_purchase,
-- считаем среднюю суммарную стоимость покупок на одного платящего/неплатящего игрока
	round(sum(e.amount)::NUMERIC/count(DISTINCT u.id ), 2) AS avg_sum_cost
-- присоединяем к таблице users таблицу events для определения количества и стоимости покупок
FROM fantasy.users u 
JOIN fantasy.events e ON u.id = e.id
WHERE e.amount > 0 --исключаем из данных покупки с нулевой стоимостью
GROUP BY u.payer; -- групируем данные по платящим и неплатящим игрокам
-- Решение:
--+-----------+------------+--------------------+---------------+
--| group_user| count_user | avg_count_purchase | avg_sum_cost  |
--+-----------+------------+--------------------+---------------+
--| неплатящий| 	 11348 |                97  |       48588.47|
--| платящий  |  	  2444 |                81  |       55467.68|
--+-----------+------------+--------------------+---------------+
-- Вывод: Платящих игроков в 4.6 раза меньше чем неплатящи. Среднее количество покупок у неплатящих игроков больше чем у платящих, 
-- но средняя суммарная стоимость покупок на одного платящего игрока выше, чем у неплатящего
	
-- 2.4: Популярные эпические предметы:
--
SELECT 
	i.game_items,
	count(e.item_code) AS total_item_code, -- считаем общее количество продаж
	round(count(e.item_code)/
	 (SELECT count(*) FROM fantasy.events WHERE amount>0)::NUMERIC, 4) AS dolya_sales_all_purchases, --считаем долюпродаж от всех покупок
	round(count(DISTINCT e.id)/
	 (SELECT count(DISTINCT id) FROM fantasy.events WHERE amount>0)::NUMERIC, 4) AS dolya_users_purchasers_item --считаем долю игроков, которые хотябы раз покупали эпический предмет
FROM fantasy.items i
LEFT JOIN fantasy.events e ON i.item_code = e.item_code
WHERE e.amount > 0
GROUP BY i.game_items
ORDER BY total_item_code DESC 
--Решение:
--+--------------------------+---------------+-------------------------+---------------------------+
--| game_items               |total_item_code|dolya_sales_all_purchases|dolya_users_purchasers_item|
--+--------------------------+---------------+-------------------------+---------------------------+
--| Book of Legends          |        1004516|                   0.7687|                     0.8841|
--| Bag of Holding           |         271875|                   0.2081|                     0.8677|
--| Necklace of Wisdom       |          13828|                   0.0106|                     0.1180|
--| Gems of Insight          |           3833|                   0.0029|                     0.0671|
--| Treasure Map             |           3183|                   0.0024|                     0.0594|
--| Amulet of Protection     |           1078|                   0.0008|                     0.0323|
--| Silver Flask             |            795|                   0.0006|                     0.0459|
--| Strength Elixir          |            580|                   0.0004|                     0.0240|
--| Glowing Pendant          |            563|                   0.0004|                     0.0257|
--| Gauntlets of Might       |            514|                   0.0004|                     0.0204|
--| Sea Serpent Scale        |            458|                   0.0004|                     0.0043|
--| Ring of Wisdom           |            379|                   0.0003|                     0.0225|
--+--------------------------+---------------+-------------------------+---------------------------+
-- Вывод: Основная доля продаж эпических предметов приходится на Book of Legends (76.87%) и Bag of Holding (20.81%) 
-- Так же по этим предметам высокая доля игроков купивших хотя бы один раз 88.41% и 86.77% соответственно.

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
--
WITH gamers_stat AS (
-- Считаем статистику по покупателям
	SELECT
		race_id, --расы
		count(*) AS total_gamers --всего играков
	FROM fantasy.users u 
	GROUP BY race_id
),
buyers_stat AS (
-- Считаем статистику по покупкам с фильтрацией нулевых покупок
	SELECT
		race_id, -- расы 
		count(DISTINCT u.id) AS total_buyers, --всего покупателей
		count(DISTINCT u.id) FILTER (WHERE u.payer=1) AS total_payer_buyers, --всего платящих покупателей
		COALESCE(SUM(amount), 0) AS total_amount --общая сумма продаж
	FROM fantasy.events e
	LEFT JOIN fantasy.users u USING (id)
	WHERE e.amount > 0
	GROUP BY race_id 
),
orders_stat AS (
-- Считаем статистику по трназакциям с фильтрацией нулевых покупок
	SELECT
		race_id,
		count(DISTINCT e.transaction_id) AS total_orders --всего совершенных покупок
	FROM fantasy.events e
	LEFT JOIN fantasy.users u USING (id)
	WHERE e.amount > 0
	GROUP BY race_id
)
SELECT
    race, --расы
    -- выводим статистику по игрокам
    total_gamers, --всего игроков
    total_buyers, --всего покупателей
    round(total_buyers::NUMERIC/total_gamers, 4) AS buyers_share, --доля покупателей
    round(total_payer_buyers::NUMERIC/total_buyers, 4) AS payer_buyers_share, --доля покупателей плательщиков
    -- выводим статистику по покупкам
    round(total_orders::NUMERIC/total_buyers) AS orders_per_buyer, --заказы на одного покупателя
    round(total_amount::NUMERIC/total_buyers, 2) AS total_amount_per_buyer, --общая сумма на одного покупателя
    round(total_amount::NUMERIC/total_orders, 2) AS avg_amount_per_buyer --средняя сумма на одного покупателя
FROM gamers_stat 
JOIN buyers_stat USING(race_id) 
JOIN orders_stat USING(race_id)
JOIN fantasy.race USING(race_id)
ORDER BY orders_per_buyer DESC;
-- Решение:
--+---------+------------+------------+------------+------------------+----------------+----------------------+--------------------+
--| race    |total_gamers|total_buyers|buyers_share|payer_buyers_share|orders_per_buyer|total_amount_per_buyer|avg_amount_per_buyer|
--+---------+------------+------------+------------+------------------+----------------+----------------------+--------------------+
--| Human   |        6328|        3921|      0.6196|            0.1801|             121|              48935.22|              403.08|
--| Angel   |        1327|         820|      0.6179|            0.1671|             107|              48665.73|              455.65|
--| Hobbit  |        3648|        2266|      0.6212|            0.1770|              86|              47621.80|              552.91|
--| Orc     |        3619|        2276|      0.6289|            0.1740|              82|              41761.03|              510.91|
--| Northman|        3562|        2229|      0.6258|            0.1821|              82|              62518.17|              761.47|
--| Elf     |        2501|        1543|      0.6170|            0.1627|              79|              53761.70|              682.34|
--| Demon   |        1229|         737|      0.5997|            0.1995|              78|              41194.84|              529.02|
--+---------+------------+------------+------------+------------------+----------------+----------------------+--------------------+



