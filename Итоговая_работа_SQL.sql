-- Итоговая Работа Задание №1 (Правильно)
-- Выведите название самолетов, которые имеют менее 50 посадочных мест.

select model "Название", count(s.seat_no) "Количество посадочных мест"
from aircrafts a 
	join seats s on s.aircraft_code = a.aircraft_code
group by model
having count(s.seat_no) < 50

- - Ответ 1 самолёт 'Cessna 208 Caravan'

-- Итоговая Работа Задание №2 (Правильно)
-- Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

select 
	date_trunc('month', book_date), 
	lag(sum(total_amount)) over (order by date_trunc('month', book_date)),
	lead(sum(total_amount)) over (order by date_trunc('month', book_date)),
	round((sum(total_amount) - lag(sum(total_amount)) over (order by date_trunc('month', book_date)))
		/lag(sum(total_amount)) over (order by date_trunc('month', book_date))*100, 2) "Процентное изменение"
from bookings b
group by 1
order by 1

-- Итоговая Работа Задание №3 (Правильно)
-- Выведите названия самолетов не имеющих бизнес - класс. 
-- Решение должно быть через функцию array_agg.

select model "Название самолетов"
from
(select distinct model, array_agg(fare_conditions) over (partition by model) m
from seats s 
join aircrafts a on a.aircraft_code = s.aircraft_code) t
where not m @> '{Business}'

-- Итоговая Работа Задание №4 (На проверку)
--Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, 
--учитывая только те самолеты, которые летали пустыми и только те дни, 
--где из одного аэропорта таких самолетов вылетало более одного.
--В результате должны быть код аэропорта, дата, количество пустых мест и накопительный итог.

select departure_airport "код аэропорта",
		scheduled_departure::date "дата вылета",
		place as "число пустых мест",
		sum(place) over (partition by departure_airport,scheduled_departure::date
			order by scheduled_departure::date rows between unbounded preceding and current row) "накопительный итог"
from flights
join
	(select aircraft_code,
	count(*) as place
	from seats
	group by aircraft_code) s on flights.aircraft_code = s.aircraft_code
where flight_id in
	(select flight_data.flight_id
		from
			(select f.flight_id,
					plains.aircraft_code,
					plains.seat_no,
					f.status
			from flights f
			join
				(select s.seat_no,
						p.aircraft_code
					from aircrafts p
					join seats s on s.aircraft_code = p.aircraft_code) plains on plains.aircraft_code = f.aircraft_code
				where (f.status = 'Arrived' or f.status = 'Departed')) flight_data
			left join boarding_passes b on b.flight_id = flight_data.flight_id
			and b.seat_no = flight_data.seat_no
			join
				(select aircraft_code,
					count(*) as sum_of_places
				from seats
				group by aircraft_code) pl on flight_data.aircraft_code = pl.aircraft_code
			where b.seat_no is null
			group by flight_data.flight_id, pl.sum_of_places
			having count(*) = pl.sum_of_places)
group by departure_airport, scheduled_departure::date,place
having count(*) > 1
 
-- Итоговая Работа Задание №5 (Правильно)	
-- Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
-- Выведите в результат названия аэропортов и процентное отношение.
-- Решение должно быть через оконную функцию.

select distinct on (f.flight_no) r.departure_airport_name "аэропорт вылета",
r.arrival_airport_name as "аэропорт прибытия",
round(((count(*) over (partition by f.flight_no)::real / count(*) over ()::real) * 100)::numeric,2) "процент от общего числа"
from flights f
join routes r on r.flight_no = f.flight_no;

	
-- Итоговая Работа Задание №6 (Правильно)
-- Выведите количество пассажиров по каждому коду сотового оператора, 
-- если учесть, что код оператора - это три символа после +7 

select distinct
	count(passenger_id) "Количество пассажиров", 
	substring (contact_data ->> 'phone' from 3 for 3) "Код оператора"
from tickets t
group by 2 
order by 2
 
-- Итоговая Работа Задание №7 (Правильно)
-- Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
-- До 50 млн - low
-- От 50 млн включительно до 150 млн - middle
-- От 150 млн включительно - high
-- Выведите в результат количество маршрутов в каждом полученном классе.

  select count("Маршрут") "Количество маршрутов", t.x
  from
  (
	  select distinct concat(departure_airport, ' - ', arrival_airport) "Маршрут", sum(amount) "Сумма билетов",
	  	case 
	  		when sum(amount) < 50000000 then 'low'
	  		when sum(amount) >= 150000000 then 'high'
	  		else'middle'
	  	end x
	  from ticket_flights tf
	  join flights f on f.flight_id = tf.flight_id
	  group by f.departure_airport, f.arrival_airport
	    ) t
  group by t.x
  
-- Итоговая Работа Задание №8 (Правильно)
-- Вычислите медиану стоимости билетов, 
-- медиану размера бронирования и 
-- отношение медианы бронирования к медиане стоимости билетов, округленной до сотых.
  
with median_tickets as
	(select percentile_cont(0.5) within group ( order by tf.amount)
		from ticket_flights tf),
	median_bookings as
	(select percentile_cont(0.5) within group ( order by b.total_amount)
		from bookings b)
select b.percentile_cont as "медиана бронирования",
	t.percentile_cont as "медиана билета",
	round((b.percentile_cont / t.percentile_cont)::numeric,
2) "отношение"
from median_bookings b, median_tickets t;

