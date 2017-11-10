MATCH p = (root:Usuario {screenName: "LillyMunster3"})-[:INFECTA*1..]->(m)
RETURN p, length(p) as L
ORDER BY L DESC
LIMIT 1