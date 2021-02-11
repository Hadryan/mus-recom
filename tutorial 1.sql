-- Now we've got some data, let's start to explore the dataset.

-- ### Dataset
-- image::http://dev.assets.neo4j.com.s3.amazonaws.com/wp-content/uploads/Northwind_diagram.jpg[]
-- The Northwind Graph provides us with a rich dataset, but primarily we're interested in Customers and their Orders.   In a Graph, the data is modelled like so:
-- image::https://raw.githubusercontent.com/adam-cowley/northwind-neo4j/master/product-model.png[]

SET graph_path = sample02_graph;

MATCH (v:music)
where id(v) = 4.4
set v."key"= 6,  v."mode"= 1,    v."tempo"= 153.902,    v."energy"= 0.354, v."valence"= 0.792, 
v."liveness"= 0.381,    v."loudness"= -9.486,     v."duration_ms"= 126464, 
v."speechiness"= 0.0543,     v."acousticness"=  0.595,     v."danceability"= 0.766, 
v."time_signature"= 4,     v."instrumentalness"= 0;


-- ### Popular Products
-- To find the most popular products in the dataset, we can follow the path from `:Customer` to `:Product`

match (p:people)-[l:LISTENS]->(m:Music)
return p.id, m.id, count(l) as listens
order by listens desc
limit 5;

MATCH (p1:people)-[x:Listens]->(s:music)<-[y:listens]-(p2:people)
WITH SUM(x.created_at * y.created_at) AS xyDotProduct,
 SQRT(x.created_at^2) AS xLength,
 SQRT(x.created_at^2) AS yLength,
 p1, p2
MERGE (p1)-[s:SIMILARITY]-(p2)
SET s.similarity = xyDotProduct / (xLength * yLength);


MATCH (b:people)-[r:listens]->(m:music), (b)-[s:SIMILARITY]-(a:people {id:581}) 
WHERE NOT exists ((a)-[l:listens]->(m)) 
WITH m, s.similarity AS similarity, r.created_at AS rating ORDER BY m.id, similarity DESC 
WITH m.id AS song_id, rating
WITH song_id, COLLECT(rating) AS ratings 
WITH song_id, 1.0 / length(ratings) AS reco ORDER BY reco DESC 
RETURN song_id AS song_id, reco AS recommendation;

                                    
MATCH (c:people)-[l:listens]->(p:music)
WITH c, count(l) as total
MATCH (c)-[:listens]->(p:music)
WITH c, total, p, count(p.acousticness) as orders
with c, total, p, orders, round(orders*1000.0/total)/1000.0 as rating
MERGE (c)-[rated:RATED {
		   total_count: total, order_count: orders, rating: rating
		   }]->(p)
		                                       
MATCH path = (c:people)-[r:RATED]->(p:music)
RETURN c.id as user, r.total_count, p.id as music, r.order_count, r.rating, path
limit 100;
	   
-- not very useful	   
MATCH (p1:people)-[l1:listens]->(m1:music)
MATCH (p2:people)-[l2:listens]->(m2:music)
WHERE m2 <> m1 AND (m2.acousticness / m1.acousticness) > 0.9
Return m1.id as m1, m2.id as m2, p1.id as p1, p2.id as p2, (m1.acousticness - m2.acousticness) as diff  order by diff desc limit 10	
	   
-- acousticness difference is less than 10%	   
MATCH (p1:people)-[l1:listens]->(m1:music)
MATCH (m2:music)
WHERE p1.id = 1 AND m2 <> m1 AND (m2.acousticness - m1.acousticness) < 0.1
Return distinct id(m1), id(m2), m1.id as m1, m2.id as m2, abs(m1.acousticness - m2.acousticness) as diff  order by diff asc limit 1000
	
-- with id	   
MATCH (p1:people)-[l1:listens]->(m1:music)
MATCH (m2:music)
WHERE p1.id = 581 AND m1.id = 1431 AND m2 <> m1 AND abs(m2.acousticness - m1.acousticness) < 0.1
Return distinct id(m1), id(m2), m1.id as m1, m2.id as m2, abs(m1.acousticness - m2.acousticness) as diff  order by diff asc limit 1000	   
	   
	   
MATCH (p1:people)-[l1:listens]->(m1:music)
MATCH (m2:music)
where m1.id = 2283 AND m2.id = 542 AND m2 <> m1
With p1, l1, m1, m2, ((m1.acousticness * m2.acousticness) + (m1.liveness * m1.liveness)) as similarity, ( sqrt((m1.acousticness + m1.liveness)^2) * sqrt((m1.acousticness + m1.liveness)^2) ) as jazr
with p1, l1, m1, m2, similarity, jazr , similarity / jazr as shebahat
Return distinct id(m1), id(m2), m1.id as m1, m2.id as m2, similarity, jazr, shebahat,  abs(m1.acousticness - m2.acousticness) as diff  order by shebahat desc limit 100	   
	   
// Scaling
MATCH (p:music)
WITH max(p.speechiness) as speechiness_max, min(p.speechiness) AS speechiness_min, max(p.duration_ms) as duration_max, min(p.duration_ms) AS duration_min,
		max(p.loudness) as loudness_max, min(p.loudness) AS loudness_min, max(p.tempo) as tempo_max, min(p.tempo) AS tempo_min
WITH speechiness_min, duration_min, loudness_min, tempo_min, speechiness_max - speechiness_min as speechiness_diff,
		duration_max - duration_min AS duration_diff, loudness_max - loudness_min AS loudness_diff, tempo_max - tempo_min AS tempo_diff 
MATCH (p1:music) 
WHERE p1.id = 542
WITH (p1.speechiness - speechiness_min) * 1.0 / speechiness_diff as speechiness_scaled, (p1.duration_ms - duration_min) * 1.0 / duration_diff as duration_scaled,
		(p1.loudness - loudness_min) * 1.0 / loudness_diff as loudness_scaled, (p1.tempo - tempo_min) * 1.0 / tempo_diff as tempo_scaled
RETURN *
	   
