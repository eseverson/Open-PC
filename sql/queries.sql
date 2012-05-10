SELECT username,up.u_id, up.p_id school, team_name, count(*), max(s.judgement) FROM 
  (SELECT * FROM problem p INNER JOIN 
    (SELECT users.u_id,username FROM users WHERE user_type='3') u) up 
        LEFT JOIN submission s ON s.p_id=up.p_id AND s.u_id=up.u_id GROUP BY s.p_id, s.u_id ORDER BY s.u_id, s.p_id;
			
			
			
SELECT * FROM problem p INNER JOIN (SELECT users.u_id,username,team_name,school FROM users JOIN team ON users.u_id=team.u_id WHERE users.user_type='3') u;


SELECT ps.u_id, ps.username, team.team_name, team.school, ps.p_id, ps.tries, ps.best, r.solved, r.submits FROM 
    (SELECT up.u_id,name,username,up.p_id,s_id,count(judgement) AS tries,max(judgement) AS best FROM 
     (SELECT * FROM problem p INNER JOIN 
      (SELECT users.u_id,username FROM users WHERE user_type='3') u) up 
    LEFT JOIN submission s ON s.p_id=up.p_id AND s.u_id=up.u_id GROUP BY up.u_id,up.p_id) ps 
      LEFT JOIN (SELECT u_id, SUM(IF(s.best=100,1,0)) AS solved, SUM(numSubs) AS submits FROM 
        (SELECT u_id,p_id,count(*) AS numSubs,max(judgement) AS best FROM submission GROUP BY u_id,p_id) s GROUP BY u_id) r 
          ON ps.u_id=r.u_id 
            JOIN team ON team.u_id=ps.u_id ORDER BY solved DESC, submits, ps.u_id, ps.p_id;
        
select count(judgement='100') from users u join (select u_id from submissions where judgement='100' group by p_id) s 
    ON u.u_id=s.u_id group by 


/* returns list of u_id's and number of solved problems */
select u_id, count(*) as solved from (select u_id,p_id from submission where judgement='100' group by u_id,p_id) s group by u_id;

SELECT u_id, count(*) as solved, sum(numSubs) as submits FROM 
        (SELECT u_id,p_id,count(*) as numSubs,max(judgement) FROM submission GROUP BY u_id,p_id) s GROUP BY u_id;
        
SELECT * FROM 
  (SELECT * FROM problem INNER JOIN 
    (SELECT * FROM users WHERE user_type='3') u) pu LEFT JOIN 
      submission s ON s.u_id=pu.u_id, s.p_id=pu..p_id GROUP BY pu.u_id,pu.p_id
