-- Now we've got some data, let's start to explore the dataset.

-- ### Dataset
-- image::http://dev.assets.neo4j.com.s3.amazonaws.com/wp-content/uploads/Northwind_diagram.jpg[]
-- The Northwind Graph provides us with a rich dataset, but primarily we're interested in Customers and their Orders.   In a Graph, the data is modelled like so:
-- image::https://raw.githubusercontent.com/adam-cowley/northwind-neo4j/master/product-model.png[]

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
	   
	   
	   
