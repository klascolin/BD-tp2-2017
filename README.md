# Impacto de noticias falsas en redes sociales
(fake news' impact in social media)

**Base de datos:** NoSql Graph oriented

**Tecnología:** [Neo4j](https://neo4j.com)

## Introducción (summary)

 En este trabajo practico abordamos la tematica del impacto de las noticias falsas en las redes sociales. Dada una muestra de datos (tomada de [hoaxy](http://hoaxy.iuni.iu.edu)) buscamos respondernos una serie de preguntas utilizando una bate de datos orientada a grafos.
 
 In this project we going to address the problem of fake news in the social media. Given a set of data (from [hoaxy](http://hoaxy.iuni.iu.edu)) We going to try answer a set of questions using a no sql graph oriented database.

## Desarrollo

**Conversión de datos .json a .csv**
 Nuesto primer paso es convertir los datos que provienen en formato [json](http://www.json.org) a un formato aceptado por la base de datos ([csv](https://en.wikipedia.org/wiki/Comma-separated_values)). Para esto utilizamos [jq](https://stedolan.github.io/jq/):
```
jq -r '.edges[] | [.canonical_url, .date_published, .domain, .from_user_id, .from_user_screen_name, .id,.is_mention, .site_type,.title, .to_user_id, .to_user_screen_name, .tweet_created_at, .tweet_id, .tweet_type, .url_id | tostring]  | @csv ' noticias.json
```
 Con la instrucción anterior vamos a obtener un archivo llamado noticias.json el cual debemos importar en la siguiente sección.
 
**Importar proyecto**
 
 El primer paso aquí es colocar el archivo noticias.json en la carpera llamada "import" de node4j (esto requiere que esté [instalado localemente](https://neo4j.com/docs/operations-manual/current/installation/)). Luego ejecutar:
 
 
###### Cargar noticias

1. Creamos los nodos "Noticia" con los atributos url, idNoticia y titulo.
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Noticia{url:line[0],idNoticia:line[5],titulo:line[8]});
```

2. Creamos los nodos "Usuario" con screenName y userId. Estos son los usuarios que crearon noticias
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Usuario{screenName:line[4],userId:line[3]});
```

2. Creamos los nodos "Usuario" con screenName y userId. Estos son los usuarios que recibieron noticias. (no se deberían crear repetidos)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MERGE (n:Usuario{screenName:line[10],userId:line[9]});
```

3. Creamos las relaciones entre noticias y sus creadores (transición IMPACTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (n:Noticia {titulo: line[8]})
MATCH (u:Usuario {userId:line[3]})
MERGE (n)-[:IMPACTA]->(u);
```

4. Creamos las relaciones entre usuarios y las noticias que leyeron (transición IMPACTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (n:Noticia {titulo: line[8]})
MATCH (u:Usuario {userId:line[9]})
MERGE (n)-[:IMPACTA]->(u);
```

![Alt text](/img/graphImpacta_0.png?raw=true)

###### Agregar la relacion de infeccíon

5. Creamos las relaciones entre usuarios que se envian noticias (transición INFECTA)
```
LOAD CSV FROM "file:///noticias.csv" AS line
MATCH (u1:Usuario {userId:line[3]})
MATCH (u2:Usuario {userId:line[9]})
MERGE (u1)-[:INFECTA]->(u2);
```
![Alt text](/img/graphInfecta_0.png?raw=true)

## Analisís

 A continuación responderemos una serie de consultas formuladas para entender mejor el dominio del problema.
 
1. Enumere las noticias que han impactado en más del 25 % de la comunidad.

```
match (u:Usuario)
with count(u) as userNodes
match (n:Noticia)-[r]-()
with userNodes, n, count(r) as degree 
where degree > userNodes*0.25
return n.titulo AS node, degree
order by degree;
```

2. Genere el sub-grafo de usuarios que consumen las mismas noticias.

```
MATCH (n:Noticia)-[:IMPACTA]->(u:Usuario)
RETURN n as Noticia, collect(u) as Usuarios, count(u) as CantUsuarios
```

3. ¿Existen usuarios de Twitter que han estado en contacto con más del 20 % del lote de noticias?

```
match(u:Usuario)
match( (n2:Noticia)-[r]->(u) )
with u, count(r) as inDegree
match (n1:Noticia) 
with u, inDegree, count(n1) as news
where inDegree >= 0.2*news
return u.userId as Node, inDegree
```

4. ¿Cómo es la distribución de los grados de entrada y salida de los nodos? Presente la información en un histograma.

5. Llamaremos root-influencers a los nodos raíces del grafo de infección. Escriba una consulta que dado un nodo de usuario en el grafo de infección diga si es root-influencer o no. ¿Qué proporción hay de root-influencers? Muestre la información apropiadamente.

```
MATCH (root:Usuario {screenName: "beforeitsnews"})-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root) 
RETURN count(root) > 0 as esRoot
```

```
MATCH (user:Usuario)
WITH count(distinct(user)) as total
MATCH (root:Usuario)-[:INFECTA]->()
WHERE NOT ()-[:INFECTA]->(root) 
RETURN count(distinct(root))*100/total as proporcion
```

6. Calcule el grado de la infección para un root-influencer dado. El grado de infección está dado por el camino más largo que se puede alcanzar desde un root-influencer.

7. Pode el grafo quitando todos los root-influencers y muestre gráficamente como queda el grafo resultante. Si la información es muy grande, recorte apropiadamente.

8. Considere la introducción de índices a los modelos. Evalué la performance de las consultas implementadas con y sin utilización de índices.

## Conclusión

