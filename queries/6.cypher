match p = (root)-[:INFECTA*1..]->(m)
WHERE NOT ()-[:INFECTA]->(root)
return p, length(p) as L
order by L desc
limit 1