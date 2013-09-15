DROP TABLE IF EXISTS `cms_sites`;
CREATE TABLE IF NOT EXISTS `cms_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `full_uri` varchar(255) DEFAULT NULL,
  `mobile_full_uri` varchar(255) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `related_site` text,
  `map_key` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

INSERT INTO `cms_sites` (`id`, `unid`, `state`, `created_at`, `updated_at`, `name`, `full_uri`, `mobile_full_uri`, `node_id`, `related_site`, `map_key`) VALUES
(1, 1, 'public', '2011-02-16 19:37:04', '2011-07-08 10:28:22', 'ジョールリ市', 'http://192.168.0.2/', '', 1, '', '');


DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_creators`;
CREATE TABLE `sys_creators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_editable_groups`;
CREATE TABLE `sys_editable_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_ids` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_files`;
CREATE TABLE `sys_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `tmp_id` varchar(255) DEFAULT NULL,
  `parent_unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `title` text,
  `mime_type` text,
  `size` int(11) DEFAULT NULL,
  `image_is` int(11) DEFAULT NULL,
  `image_width` int(11) DEFAULT NULL,
  `image_height` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parent_unid` (`parent_unid`,`name`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_groups`;
CREATE TABLE `sys_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `state` varchar(15) DEFAULT NULL,
  `web_state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `parent_id` int(11) NOT NULL,
  `level_no` int(11) DEFAULT NULL,
  `code` varchar(255) NOT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `layout_id` int(11) DEFAULT NULL,
  `ldap` int(11) NOT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `name_en` varchar(255) DEFAULT NULL,
  `group_s_name` text,
  `tel` varchar(255) DEFAULT NULL,
  `outline_uri` varchar(255) DEFAULT NULL,
  `email` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

INSERT INTO `sys_groups` (`id`, `state`, `web_state`, `created_at`, `updated_at`, `parent_id`, `level_no`, `code`, `sort_no`, `layout_id`, `ldap`, `ldap_version`, `name`, `name_en`, `group_s_name`, `tel`, `outline_uri`, `email`) VALUES
(1,'enabled','closed','2011-02-16 19:37:04','2011-02-16 19:37:04',0,1,'root',1,NULL,0,NULL,'組織','soshiki',NULL,NULL,NULL,NULL),
(2,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',1,2,'001',2,NULL,1,'1326423565','企画部','kikakubu',NULL,NULL,NULL,NULL),
(3,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',9,3,'002001',1,NULL,1,'1326423565','部長室','buchoshitsu',NULL,NULL,NULL,NULL),
(4,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',2,3,'001002',2,NULL,1,'1326423565','秘書広報課','hisyokohoka',NULL,NULL,NULL,NULL),
(5,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',2,3,'001003',3,NULL,1,'1326423565','人事課','jinjika',NULL,NULL,NULL,NULL),
(6,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',2,3,'001004',4,NULL,1,'1326423565','企画政策課','kikakuseisakuka',NULL,NULL,NULL,NULL),
(7,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',2,3,'001005',5,NULL,1,'1326423565','行政情報室','gyoseijohoshitsu',NULL,NULL,NULL,NULL),
(8,'enabled','closed','2011-02-16 19:37:04','2011-08-18 10:42:13',2,3,'001006',6,NULL,0,NULL,'IT推進課','itsuishinka','IT推進課',NULL,NULL,NULL),
(9,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',1,2,'002',3,NULL,1,'1326423565','総務部','somubu',NULL,NULL,NULL,NULL),
(10,'enabled','closed','2011-02-16 19:37:04','2011-08-18 10:42:13',9,3,'002001',1,NULL,0,NULL,'部長室','buchoshitsu','部長室',NULL,NULL,NULL),
(11,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',9,3,'002002',2,NULL,1,'1326423565','財政課','zaiseika',NULL,NULL,NULL,NULL),
(12,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',9,3,'002003',3,NULL,1,'1326423565','庁舎建設推進室','chosyakensetsusuishinka',NULL,NULL,NULL,NULL),
(13,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:47',9,3,'002004',4,NULL,1,'1326423565','管財課','kanzaika',NULL,NULL,NULL,NULL),
(14,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',9,3,'002005',5,NULL,1,'1326423565','税務課','zeimuka',NULL,NULL,NULL,NULL),
(15,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',9,3,'002006',6,NULL,1,'1326423565','納税課','nozeika',NULL,NULL,NULL,NULL),
(16,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',9,3,'002007',7,NULL,1,'1326423565','市民安全局','shiminanzenkyoku',NULL,NULL,NULL,NULL),
(17,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'003',4,NULL,1,'1326423565','市民部','shiminbu',NULL,NULL,NULL,NULL),
(18,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'004',5,NULL,1,'1326423565','環境管理部','kankyokanribu',NULL,NULL,NULL,NULL),
(19,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'005',6,NULL,1,'1326423565','保健福祉部','hokenhukushibu',NULL,NULL,NULL,NULL),
(20,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'006',7,NULL,1,'1326423565','産業部','sangyobu',NULL,NULL,NULL,NULL),
(21,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'007',8,NULL,1,'1326423565','建設部','kensetsubu',NULL,NULL,NULL,NULL),
(22,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'008',9,NULL,1,'1326423565','特定事業部','tokuteijigyobu',NULL,NULL,NULL,NULL),
(23,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'009',10,NULL,1,'1326423565','会計','kaikei',NULL,NULL,NULL,NULL),
(24,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'010',11,NULL,1,'1326423565','水道部','suidobu',NULL,NULL,NULL,NULL),
(25,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'011',12,NULL,1,'1326423565','教育委員会','kyoikuiinkai',NULL,NULL,NULL,NULL),
(26,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'012',13,NULL,1,'1326423565','議会','gikai',NULL,NULL,NULL,NULL),
(27,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'013',14,NULL,1,'1326423565','農業委員会','nogyoiinkai',NULL,NULL,NULL,NULL),
(28,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'014',15,NULL,1,'1326423565','選挙管理委員会','senkyokanriiinkai',NULL,NULL,NULL,NULL),
(29,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'015',16,NULL,1,'1326423565','監査委員','kansaiin',NULL,NULL,NULL,NULL),
(30,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'016',17,NULL,1,'1326423565','公平委員会','koheiiinkai',NULL,NULL,NULL,NULL),
(31,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'017',18,NULL,1,'1326423565','消防本部','syobohonbu',NULL,NULL,NULL,NULL),
(32,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'018',19,NULL,1,'1326423565','住民センター','jumincenter',NULL,NULL,NULL,NULL),
(33,'enabled','closed','2011-02-16 19:37:04','2012-01-13 12:49:48',1,2,'019',20,NULL,1,'1326423565','公民館','kominkan',NULL,NULL,NULL,NULL),
(34,'enabled','public','2011-12-07 09:55:25','2012-01-13 12:49:47',2,3,'001006IT',NULL,NULL,1,'1326423565','推進課',NULL,NULL,NULL,NULL,NULL),
(35,'enabled','public','2011-12-07 10:22:55','2012-01-13 12:49:47',2,3,'001001',NULL,NULL,1,'1326423565','部長室',NULL,NULL,NULL,NULL,NULL);


DROP TABLE IF EXISTS `sys_languages`;
CREATE TABLE `sys_languages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `title` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

INSERT  INTO `sys_languages` (`id`, `state`, `created_at`, `updated_at`, `sort_no`, `name`, `title`) VALUES
(1,'enabled','2011-02-16 19:37:04','2011-02-16 19:37:04',1,'japanese','日本語');

--

DROP TABLE IF EXISTS `sys_ldap_synchros`;
CREATE TABLE `sys_ldap_synchros` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `version` varchar(10) DEFAULT NULL,
  `entry_type` varchar(15) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `sort_no` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `name_en` varchar(255) DEFAULT NULL,
  `group_s_name` text,
  `email` varchar(255) DEFAULT NULL,
  `kana` varchar(255) DEFAULT NULL,
  `title` text,
  `employee_type` text,
  PRIMARY KEY (`id`),
  KEY `version` (`version`,`parent_id`,`entry_type`)
) DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `sys_maintenances`;
CREATE TABLE `sys_maintenances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `title` text,
  `body` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `sys_messages`;
CREATE TABLE `sys_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `title` text,
  `body` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `sys_object_privileges`;
CREATE TABLE `sys_object_privileges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `role_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `item_unid` int(11) DEFAULT NULL,
  `action` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `item_unid` (`item_unid`,`action`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_publishers`;
CREATE TABLE `sys_publishers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `published_path` text,
  `content_type` text,
  `content_length` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) CHARSET=utf8;


DROP TABLE IF EXISTS `sys_recognitions`;
CREATE TABLE `sys_recognitions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `recognizer_ids` varchar(255) DEFAULT NULL,
  `info_xml` text,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `sys_role_names`;
CREATE TABLE `sys_role_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `title` text,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_sequences`;
CREATE TABLE `sys_sequences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`,`version`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_tasks`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sys_tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `process_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_unids`;
CREATE TABLE `sys_unids` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `model` varchar(255) NOT NULL,
  `item_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_user_logins`;
CREATE TABLE `sys_user_logins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `sys_users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sys_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `air_login_id` varchar(255) DEFAULT NULL,
  `state` varchar(15) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ldap` int(11) NOT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `auth_no` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `name_en` text,
  `account` varchar(255) DEFAULT NULL,
  `password` text,
  `mobile_access` int(11) DEFAULT NULL,
  `mobile_password` varchar(255) DEFAULT NULL,
  `email` text,
  `remember_token` text,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `kana` varchar(255) DEFAULT NULL,
  `sort_no` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;

INSERT  DELAYED INTO `sys_users` (`id`, `air_login_id`, `state`, `created_at`, `updated_at`, `ldap`, `ldap_version`, `auth_no`, `name`, `name_en`, `account`, `password`, `mobile_access`, `mobile_password`, `email`, `remember_token`, `remember_token_expires_at`, `kana`) VALUES
(1,NULL,'enabled','2011-02-16 19:37:04','2012-01-13 12:49:47',0,'1326423565',5,'システム管理者','admin admin','admin','admin',0,'admin','admin@demo.joruri.org',NULL,NULL,NULL),
(2,NULL,'enabled','2011-02-16 19:37:04','2012-01-13 12:49:47',0,'1326423565',2,'徳島　太郎 ','user1 user1','user1','user1',1,'user1pass','user1@demo.joruri.org',NULL,NULL,NULL),
(3,NULL,'enabled','2011-02-16 19:37:04','2012-01-13 12:49:47',0,'1326423565',2,'阿波　花子','user2 user2','user2','user2',0,'','user2@demo.joruri.org',NULL,NULL,NULL),
(4,NULL,'enabled','2011-02-16 19:37:04','2012-01-13 12:49:47',0,'1326423565',2,'吉野　三郎','user3 user3','user3','user3',0,'','user3@demo.joruri.org',NULL,NULL,NULL),
(6,NULL,'enabled','2011-07-15 13:10:04','2012-01-13 12:49:47',0,'1326423565',2,'佐藤　直一','user4 user4','user4','user4',0,'','user4@demo.joruri.org',NULL,NULL,NULL),
(7,NULL,'enabled','2011-07-15 13:10:35','2012-01-13 12:49:47',0,'1326423565',2,'鈴木　裕介','user5 user5','user5','user5',0,'','user5@demo.joruri.org',NULL,NULL,NULL),
(8,NULL,'enabled','2011-07-15 13:11:07','2012-01-13 12:49:47',0,'1326423565',2,'高橋　和寿','user6 user3','user6','user6',0,'','user6@demo.joruri.org',NULL,NULL,NULL),
(9,NULL,'enabled','2011-07-15 13:11:36','2012-01-13 12:49:47',0,'1326423565',2,'田中　彩子','user7 user7','user7','user7',0,'','user7@demo.joruri.org',NULL,NULL,NULL),
(10,NULL,'enabled','2011-07-15 13:11:53','2012-01-13 12:49:47',0,'1326423565',2,'渡辺　真由子','user8 user8','user8','user8',0,'','user8@demo.joruri.org',NULL,NULL,NULL),
(11,NULL,'enabled','2011-07-15 13:12:08','2012-01-13 12:49:47',0,'1326423565',2,'伊藤　勝','user9 user9','user9','user9',0,'','user9@demo.joruri.org',NULL,NULL,NULL);

DROP TABLE IF EXISTS `sys_users_groups`;
CREATE TABLE `sys_users_groups` (
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  KEY `user_id` (`user_id`,`group_id`)
) DEFAULT CHARSET=utf8;

INSERT INTO `sys_users_groups` (`created_at`, `updated_at`, `user_id`, `group_id`) VALUES
('2011-02-16 19:37:04','2011-02-16 19:37:04',1,4),
('2011-02-16 19:37:04','2011-02-16 19:37:04',2,4),
('2011-02-16 19:37:04','2011-02-16 19:37:04',3,4),
('2011-02-16 19:37:04','2011-02-16 19:37:04',4,4),
('2011-07-15 13:10:04','2011-07-15 13:10:04',6,5),
('2011-07-15 13:10:35','2011-07-15 13:10:35',7,5),
('2011-07-15 13:11:07','2011-07-15 13:11:07',8,5),
('2011-07-15 13:11:36','2011-07-15 13:11:36',9,6),
('2011-07-15 13:11:54','2011-07-15 13:11:54',10,6),
('2011-07-15 13:12:08','2011-07-15 13:12:08',11,6);


DROP TABLE IF EXISTS `sys_users_roles`;
CREATE TABLE `sys_users_roles` (
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  KEY `user_id` (`user_id`,`role_id`)
) DEFAULT CHARSET=utf8;
