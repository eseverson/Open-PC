CREATE DATABASE competition;

USE competition;

DROP TABLE submission;
DROP TABLE clarification;
DROP TABLE problem;
DROP TABLE users;
DROP TABLE team;
DROP TABLE sessions;

CREATE TABLE sessions (
  id CHAR(32) NOT NULL UNIQUE,
  a_session TEXT NOT NULL
);

CREATE TABLE users(
  u_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(40) NOT NULL,
  salt VARCHAR(10) NOT NULL,
  user_type INT(1) NOT NULL,
  PRIMARY KEY (u_id)
) ENGINE = INNODB;

CREATE TABLE team(
  u_id INT UNSIGNED NOT NULL,
  CONSTRAINT FOREIGN KEY (u_id) REFERENCES users(u_id) ON DELETE CASCADE ON UPDATE CASCADE,
  team_name VARCHAR(100),
  school VARCHAR(100),
  PRIMARY KEY (u_id)
) ENGINE = INNODB;
  
CREATE TABLE problem(
  p_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL UNIQUE,
  PRIMARY KEY (p_id)
) ENGINE = INNODB;

CREATE TABLE clarification(
  c_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  submission_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  answer_time TIMESTAMP,
  u_id INT UNSIGNED,
  CONSTRAINT FOREIGN KEY (u_id) REFERENCES users(u_id) ON DELETE CASCADE ON UPDATE CASCADE,
  p_id INT UNSIGNED,
  CONSTRAINT FOREIGN KEY (p_id) REFERENCES problem(p_id) ON DELETE CASCADE ON UPDATE CASCADE,
  question VARCHAR(1000),
  response VARCHAR(1000),
  response_type INT,
  PRIMARY KEY (c_id)
) ENGINE = INNODB;

CREATE TABLE submission(
  s_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  submission_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  u_id INT UNSIGNED NOT NULL,
  CONSTRAINT FOREIGN KEY (u_id) REFERENCES users(u_id) ON DELETE CASCADE ON UPDATE CASCADE,
  p_id INT UNSIGNED NOT NULL,
  CONSTRAINT FOREIGN KEY (p_id) REFERENCES problem(p_id) ON DELETE CASCADE ON UPDATE CASCADE,
  judgement INT NOT NULL,
  PRIMARY KEY (s_id)
) ENGINE = INNODB;

    
INSERT INTO users (username, password, salt, user_type) VALUES ('admin',SHA(CONCAT('admin','qwertyuiop')),'qwertyuiop',1);
INSERT INTO users (username, password, salt, user_type) VALUES ('team1',SHA(CONCAT('team1','qwertyuiop')), 'qwertyuiop', 3);
INSERT INTO team (u_id, team_name, school) VALUES (last_insert_id() ,'Comets', 'UT Dallas');
INSERT INTO users (username, password, salt, user_type) VALUES ('judge1',SHA(CONCAT('judge1','qwertyuiop')),'qwertyuiop',2);
INSERT INTO users (username, password, salt, user_type) VALUES ('team2',SHA(CONCAT('team2','qwertyuiop')),'qwertyuiop',3);
INSERT INTO team (u_id, team_name, school) VALUES (last_insert_id() ,'little bobby tables','bad school');


