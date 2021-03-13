-- external schema (view - imaginary table created by select statement)
--        |
--        V
-- conceptual schema (table - real table descriptor)
--        |
--        V
-- physical schema (real unordered records with index as first column)



-- 로그인 방법

-- cmd 열고
sqlplus system/비밀번호;
@%oracle_home%\rdbms\admin\utlxplan;
-- 또는: @$oracle_home\rdbms\admin\utlxplan;
grant all on plan_table to public;
exit;

sqlplus sys/비밀번호@localhost/orcl as sysdba
@%oracle_home%\sqlplus\admin\plustrce;
-- 또는: @$oracle_home\sqlplus\admin\plustrce;
Grant PLUSTRACE to PUBLIC;
exit;


-- 실행할거
@%oracle_home%\rdbms\admin\scott.sql

-- 모두 초기화 하고싶으면
sqlplus sys/비밀번호@localhost/orcl as sysdba
@$ORACLE_HOME/rdbms/admin/utlsampl.sql


-- 사용할 유저는
conn scott/tiger
-- 또는
sqlplus scott/tiger -- 시작할때 바로접속








-- external schema 만들어보기
drop view mytable; -- 뷰 삭제

create or replace view mytable as -- 뷰 생성
create or replace view mytable as select deptno, avg(sal) as avg_sal from emp group by deptno;
-- avg(sal) as avg_sal.




desc mytable; -- mytable의 모든 속성 출력






alter table emp rename to emp2; -- 테이블 이름 바꾸기
-- 이름 바꾸기전, 이 테이블을 포함한 다른 logical view를 만들었었다면, 지금은 사용못함.
-- 사용하려면 이름을 원래대로 바꾸거나, 스키마 다시 만들어라.

select * from mytable where deptno = 20; -- deptno가 20인 행들을 출력




set lines 200;
set pagesize 100;
-- 아담하게 출력설정



--autotrace
set autot on; -- 쿼리 처리할때 추가적으로 해시값, 오퍼레이션, 사용량 등등 나옴.
set autot off; -- 끄기



-- conceptual schema: emp
-- autostat on 해놓고...
select * from emp where deptno = 30;
create index emp_deptno on emp(deptno);
select * from emp where deptno = 30; -- 다시 돌려보기
-- execution plan부분에 INDEX RANGE SCAN이라는 단계가 추가되어있음.
drop index emp_deptno;
select * from emp where deptno = 30; -- 다시 돌려보기
-- 단계 다시 사라짐.




-- atomicity & durability
drop table; -- 있을까봐 미리 지우기
create table account(id number, balance number, primary key(id));
-- 열: id(숫자타입), balance(숫자타입), key는 id로 설정
insert into account values (1, 100);
insert into account values (2, 200); -- 원소 집어넣기
commit; -- 업데이트
update account set balance = balance - 10 where id = 1;
update account set balance = balance + 10 where id = 2; -- 원소 수정
commit; -- 업데이트
select * from account; -- 로 확인해보기.

-- commit; 하는중 컴퓨터를 끄면 crash!
-- id = 2할때 crash되었다면, id = 2는 적용이 아예 안되야함. atomicity.
-- id = 1은 커밋 완료. durability.



-- concurrency control not allowed on the same record - 버전컨트롤의 컨셉
select sal from emp where ename = 'SMITH';
update emp set sal = sal + 100 where ename = 'SMITH';
select sal from emp where ename = 'SMITH';
-- 여기서, 다른 창 열어서 
select sal from emp where ename = 'SMITH';
update emp set sal = sal * 1.1 where ename = 'SMITH'; -- 하는 순간, DEADLOCK!!!
-- 첫째창이 commit;을 하기전엔 계속 기다린다!!!
commit;
-- 하면 다시 재생한다.



--오라클에서는 order by는 이름 말고도 열 인덱스를 넣어서 열을 가져올수 있음.
select ename, empno from emp order by ename;
select ename, empno from emp order by 1;
select 1 from emp; --select에서는 안됨.




--타입이 맞지않는 레코드를 입력할때
--e.g.) DEPT(NUMBER, STRING, STRING)
insert into dept values ('XX', 'DATABASE', 'SUWON');	--오류!
insert into dept values ('50', 'DATABASE', 'SUWON');	--정상.
--e.g.) NOT NULL | NUMBER 이라 하면:
insert into dept values (NULL, 'DATABASE', 'SUWON');	--오류!
--다시 한번 같은 레코드를 넣으려하면:
insert into dept values ('50', 'DATABASE', 'SUWON');	--오류! 프라이머리 키가 중복.
insert into dept values (50, 'VLDB', 'SUWON');			--오류! 프라이머리 키가 중복.



rollback;	--undo any work done after last commit




--오라클의 미리 정의된 함수들 이용해보기:
select * from emp where hiredate = to_date('23-01-1982','dd-mm-yyyy');	--hiredate 열 참조하고 to_date() 함수 비교
--이렇게 해도 되긴 하는데 좀 햇갈릴듯
select * from emp where to_char(hiredate,'yyyy') = 1981;				--to_char() hiredate 열 참조
select * from emp where hiredate > to_date('81/09/01','yy/mm/dd');		--비교 가능







--constraint 이름정의
drop table hello;
create table hello (a int, b char(1), primary key(a));
--시스템에서 기본으로 정의된 integrity constraint
select constraint_name from user_constraints where table_name = 'HELLO';	--constraint 이름 'SYS_어쩌구' 출력

insert into hello values (1,'A');
insert into hello values (1,'A');	--똑같은 키 추가하면 'SYS_어쩌구' 제약 위배



--primary key constraint
drop table hello;
create table hello (a int, b char(1), constraint hello_pk primary key(a));	--constraint 이름 정의해서 테이블 만들기.
select constraint_name from user_constraints where table_name = 'HELLO';	--constraint 이름 'hello_pk' 출력

insert into hello values (1,'A');
insert into hello values (1,'A');	--똑같은 키 추가하면 'hello_pk' 제약 위배


--unique key constraint
drop table hello;
-- primary key unique key 모두 constraint 이름 정해보기
create table hello (a int, b char(1), constraint hello_pk primary key(a), constraint hello_uk unique key(b));
select constraint_name from user_constraints where table_name = 'HELLO';	--constraint 이름 'hello_pk', 'hello_uk' 출력
																			-- 테이블 이름은 대문자로만 찾을 수 있다!!!

insert into hello values (1,'A');
insert into hello values (1,'A');	--똑같은 키 추가하면 'hello_pk' 제약 위배
insert into hello values (2,'A');	--똑같은 키 추가하면 'hello_uk' 제약 위배 "A가 같음"






--foreign key constraint
create table parent (a int, b char(1), primary key(a));
create table child (c int, d int, constraint child_fk foreign key(d) references parent(a));
--또는 alter명령으로 constraint추가 가능
drop table child;
create table child (c int, d int);
alter table child add constraint child_fk foreign key(d) references parent(a);

insert into parent values (1,'A');
insert into child values (1,1);
insert into child values (1,null);
insert into child values (1,2);	--오류, 'child_fk' 제약 위배, parent(a)에 2가 없음.

delete from child where d = 2;
delete from parent where a = 1;	--오류, 'child_fk' 제약 위배, child(d)에 1을 쓰는 레코드가 존재함.
--가능하게 하려면:
delete from child where d = 1; --child의 레코드를 먼저 지우고
delete from parent where a = 1; --지우면 됨.


drop table parent; --오류, child 테이블이 참조하는중.
drop table child;
drop table parent;






-- cascade constraint - ORACLE은 cascade 지원 안됨.
create table parent (a int, b char(1), primary key(a));
create table child (c int, d int, 
		constraint child_fk foreign key(d) references parent(a) on delete cascade);




--deferrable constraint
create table parent (a int, b char(1), primary key(a));
create table child (c int, d int, 
		constraint child_fk foreign key(d) references parent(a) deferrable);
set constraint child_fk deferred;	--child_fk constraint를 deferred 옵션사용.

--그러면 parent에 키가 없어도 child에서 오류 안남.
insert into child values (1,2);
commit; -- commit할때 확인하여 오류가 출력이 된다.





--primary key 이외에도, parent의 unique key를 child의 foreign key로도 설정 가능
create table parent (a int, b char(1), primary key(a), unique(b));	--unique key는 b
create table child (c int, d char(1), 
		constraint child_fk foreign key(d) references parent(b)); --unique key는 b



--emp E, dept D로 별명지으기 가능
set autot on; -- 좀더 자세히 보기위해
select E.ename, E.sal from emp E, dept D where E.deptno = D.deptno and D.loc = 'NEW YORK';
-- Execution Plan: 어덯게 값을 찾았는지 서술. 오라클 DBMS가 자동으로 플랜함. e.g.) plan hash value
-- Statistics: 서버에서 plan을 실행할때 쓰인 리소스들을 조사해서 서술.
set autot off;











