/************************************************************
    Author  :   Ferenc Toth
    Remark  :   ToDos and Checklists
    Date    :   2015.07.01

    Uses PKG_DIFF package!

************************************************************/

/*============================================================================================*/
create or repalce function F_TRUE_OR_FALSE ( I_TRUE_OR_FALSE in boolean) return number is
/*============================================================================================*/
begin
    if I_TRUE_OR_FALSE then
        return 1;
    else
        return 0;
    end if;
end;
/


/*============================================================================================*/
create or replace function F_LISTS_ARE_DIFFER ( i_old_list    IN VARCHAR2 
                                              , i_new_list    IN VARCHAR2 
                                              , i_separator   IN VARCHAR2   := ':'
                                              , i_enclosed_by IN VARCHAR2   := NULL
                                              ) RETURN number is
/*============================================================================================*/
begin
    return F_TRUE_OR_FALSE ( PKG_DIFF.LISTS_ARE_DIFFER( i_old_list, i_new_list, i_separator, i_enclosed_by ) );
end;
/




Prompt *****************************************************************
Prompt **          I N S T A L L I N G   T O D O S                    **
Prompt *****************************************************************


/*============================================================================================*/
CREATE SEQUENCE TODO_SEQ_ID
/*============================================================================================*/
    INCREMENT BY        1
    MINVALUE            1
    MAXVALUE   9999999999
    START WITH       1000
    CYCLE
    NOCACHE;



Prompt *****************************************************************
Prompt **                        T A B L E S                          **
Prompt *****************************************************************

/*============================================================================================*/
CREATE TABLE TODO_USER_GROUPS (
/*============================================================================================*/
    CODE              VARCHAR2(   50 )    NOT NULL,
    NAME              VARCHAR2(  200 )    NOT NULL,
    CONSTRAINT        PK_TODO_USER_GROUPS            PRIMARY KEY ( CODE )
  );

/*
insert into TODO_USER_GROUPS ( CODE,NAME ) values ( 'HR','HR responsibles'  );
insert into TODO_USER_GROUPS ( CODE,NAME ) values ( 'IT','IT responsibles'  );
insert into TODO_USER_GROUPS ( CODE,NAME ) values ( 'BO','BO responsibles'  );
commit;
*/


/*============================================================================================*/
CREATE TABLE TODO_USERS_AND_GROUPS (
/*============================================================================================*/
    USER_GROUP_CODE         VARCHAR2 ( 50 ) NOT NULL,
    USER_NAME               VARCHAR2 ( 50 ) NOT NULL,
    CONSTRAINT              PK_TODO_USERS_AND_GROUPS     PRIMARY KEY ( USER_GROUP_CODE, USER_NAME ),
    CONSTRAINT              FK1_TODO_USERS_AND_GROUPS    FOREIGN KEY ( USER_GROUP_CODE ) REFERENCES TODO_USER_GROUPS  ( CODE )
  -- , CONSTRAINT              FK2_TODO_USERS_AND_GROUPS    FOREIGN KEY ( USER_NAME       ) REFERENCES USERS  ( USER_NAME )
  );



/*============================================================================================*/
CREATE TABLE TODO_WORKFLOW_TEMPLATES (
/*============================================================================================*/
    CODE                VARCHAR2(   50 )            NOT NULL,
    NAME                VARCHAR2(  200 )            NOT NULL,
    VTD_IN_DAYS         NUMBER,
    DESCRIPTION         VARCHAR2( 2000 ),
    CONSTRAINT          PK_TODO_WORKFLOW_TEMPLATES   PRIMARY KEY ( CODE )
  );


/*============================================================================================*/
CREATE TABLE TODO_STEP_TEMPLATES (
/*============================================================================================*/
    CODE                VARCHAR2(   50 )            NOT NULL,
    WORKFLOW_CODE       VARCHAR2(   50 )            NOT NULL,
    NAME                VARCHAR2(  200 )            NOT NULL,
    VTD_IN_DAYS         NUMBER,
    PRIOR_STEP_CODES    VARCHAR2( 2000 ),
    USER_GROUP_CODE     VARCHAR2(   50 )            NOT NULL,
    DESCRIPTION         VARCHAR2( 2000 ),
    CONSTRAINT          PK_TODO_STEP_TEMPLATES       PRIMARY KEY ( CODE ),
    CONSTRAINT          FK1_TODO_STEP_TEMPLATES      FOREIGN KEY ( USER_GROUP_CODE ) REFERENCES TODO_USER_GROUPS  ( CODE )
  );


/*============================================================================================*/
CREATE TABLE TODO_WORKFLOWS (
/*============================================================================================*/
    ID                  NUMBER  (   10 )            NOT NULL,
    WORKFLOW_CODE       VARCHAR2(   50 )            NOT NULL,
    SUBJECT             VARCHAR2( 2000 ),
    VTD                 DATE,
    REMARK              VARCHAR2( 2000 ),
    CREATED_AT          DATE,
    CREATED_BY          VARCHAR2(   50 )            NOT NULL,
    CONSTRAINT          PK_TODO_WORKFLOWS            PRIMARY KEY ( ID ),
    CONSTRAINT          FK1_TODO_WORKFLOWS           FOREIGN KEY ( WORKFLOW_CODE ) REFERENCES TODO_WORKFLOW_TEMPLATES  ( CODE )
  );


/*============================================================================================*/
CREATE OR REPLACE TRIGGER TR_TODO_WORKFLOWS_BIR
/*============================================================================================*/
  BEFORE INSERT ON TODO_WORKFLOWS FOR EACH ROW
BEGIN
    :NEW.ID         := NVL( :NEW.ID, TODO_SEQ_ID.NEXTVAL ); 
    :NEW.CREATED_AT := SYSDATE; 
    :NEW.CREATED_BY := NVL( V( 'APP_USER' ), USER );  
END;
/


/*============================================================================================*/
CREATE TABLE TODO_STEPS(
/*============================================================================================*/
    ID                  NUMBER  (   10 )            NOT NULL,
    WORKFLOW_ID         NUMBER  (   10 )            NOT NULL,
    STEP_CODE           VARCHAR2(   50 )            NOT NULL,
    DONE_FLAG           NUMBER  (  1,0 ),
    DONE_DATE           DATE,
    DONE_USER_NAME      VARCHAR2(   50 ),
    SUBJECT             VARCHAR2( 2000 ),
    REMARK              VARCHAR2( 2000 ),
    CONSTRAINT          PK_TODO_STEP            PRIMARY KEY ( ID ),
    CONSTRAINT          FK1_TODO_STEP           FOREIGN KEY ( STEP_CODE      ) REFERENCES TODO_STEP_TEMPLATES ( CODE ),
    CONSTRAINT          FK2_TODO_STEP           FOREIGN KEY ( DONE_USER_NAME ) REFERENCES USERS               ( USER_NAME ),
    CONSTRAINT          FK3_TODO_STEP           FOREIGN KEY ( WORKFLOW_ID    ) REFERENCES TODO_WORKFLOWS      ( ID )
  );


/*============================================================================================*/
CREATE OR REPLACE TRIGGER TR_TODO_STEPS_BIR
/*============================================================================================*/
  BEFORE INSERT ON TODO_STEPS FOR EACH ROW
BEGIN
    :NEW.ID := NVL( :NEW.ID, TODO_SEQ_ID.NEXTVAL ); 
    IF :NEW.DONE_FLAG = 1 THEN 
        :NEW.DONE_DATE      := SYSDATE; 
        :NEW.DONE_USER_NAME := NVL( V( 'APP_USER' ), USER );  
    END IF;
END;
/


/*============================================================================================*/
CREATE OR REPLACE TRIGGER TR_TODO_STEPS_BUR
/*============================================================================================*/
  BEFORE UPDATE ON TODO_STEPS FOR EACH ROW
BEGIN
    IF :NEW.DONE_FLAG = 1 AND NVL( :OLD.DONE_FLAG, 0 ) = 0 THEN 
        :NEW.DONE_DATE      := SYSDATE; 
        :NEW.DONE_USER_NAME := NVL( V( 'APP_USER' ), USER );  
    END IF;
END;
/


Prompt *****************************************************************
Prompt **                         V I E W S                           **
Prompt *****************************************************************

/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_TEMPLATES_VW AS
/*============================================================================================*/
SELECT TWT.CODE                 as WORKFLOW_CODE
     , TWT.NAME                 as WORKFLOW_NAME
     , TWT.VTD_IN_DAYS          as WORKFLOW_VTD_IN_DAYS
     , TWT.DESCRIPTION          as WORKFLOW_DESCRIPTION
     , TST.CODE                 as STEP_CODE
     , TST.NAME                 as STEP_NAME
     , TST.VTD_IN_DAYS          as STEP_VTD_IN_DAYS
     , TST.PRIOR_STEP_CODES     as STEP_PRIOR_STEP_CODES
     , TST.USER_GROUP_CODE      as STEP_USER_GROUP_CODE
     , TST.DESCRIPTION          as STEP_DESCRIPTION
  FROM TODO_WORKFLOW_TEMPLATES   TWT             
     , TODO_STEP_TEMPLATES       TST
 WHERE TST.WORKFLOW_CODE       = TWT.CODE
;

/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_WORKFLOWS_VW AS
/*============================================================================================*/
SELECT TW.ID      
     , TWT.CODE
     , TWT.NAME                
     , TWT.DESCRIPTION                
     , TW.SUBJECT 
     , TW.VTD   
     , TW.REMARK    
     , TW.CREATED_AT    
     , TW.CREATED_BY     
  FROM TODO_WORKFLOW_TEMPLATES   TWT             
     , TODO_WORKFLOWS            TW
 WHERE TW.WORKFLOW_CODE        = TWT.CODE
;

/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_EXPIRED_WORKFLOWS_VW AS
/*============================================================================================*/
SELECT ID
  FROM TODO_WORKFLOWS
 WHERE VTD < SYSDATE;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_STEPS_VW AS
/*============================================================================================*/
SELECT TWT.CODE                 as WORKFLOW_CODE
     , TWT.NAME                 as WORKFLOW_NAME
     , TWT.DESCRIPTION          as WORKFLOW_DESCRIPTION
     , TW.REMARK                as WORKFLOW_REMARK
     , TW.ID                    as WORKFLOW_ID
     , TW.SUBJECT               as WORKFLOW_SUBJECT
     , TW.VTD                   as WORKFLOW_VTD
     , TW.CREATED_AT            as WORKFLOW_CREATED_AT
     , TW.CREATED_BY            as WORKFLOW_CREATED_BY
     , TS.ID                    as STEP_ID
     , TST.CODE                 as STEP_CODE
     , TST.NAME                 as STEP_NAME
     , TST.DESCRIPTION          as STEP_DESCRIPTION
     , TST.PRIOR_STEP_CODES     as STEP_PRIOR_STEP_CODES
     , TST.USER_GROUP_CODE      as STEP_USER_GROUP_CODE
     , TS.REMARK                as STEP_REMARK
     , TS.DONE_FLAG             as STEP_DONE_FLAG
     , TS.DONE_DATE             as STEP_DONE_DATE
     , TS.DONE_USER_NAME        as STEP_DONE_USER_NAME
     , TS.SUBJECT               as STEP_SUBJECT
     , LEAST( NVL( ( SELECT MAX( B.DONE_DATE + TST.VTD_IN_DAYS ) 
                       FROM TODO_STEPS B 
                      WHERE B.WORKFLOW_ID = TS.WORKFLOW_ID
                        AND INSTR( ':'||TST.PRIOR_STEP_CODES||':',':'||B.STEP_CODE||':' ) > 0
                   ) , TW.VTD ) 
            , TW.VTD )          as STEP_VTD
  FROM TODO_WORKFLOW_TEMPLATES  TWT             
     , TODO_STEP_TEMPLATES      TST
     , TODO_WORKFLOWS           TW 
     , TODO_STEPS               TS
 WHERE TWT.CODE               = TW.WORKFLOW_CODE
   AND TST.WORKFLOW_CODE      = TWT.CODE
   AND TS.STEP_CODE           = TST.CODE
   AND TS.WORKFLOW_ID         = TW.ID
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_EXPIRED_STEPS_VW AS
/*============================================================================================*/
SELECT STEP_ID as ID
     , WORKFLOW_ID
  FROM TODO_STEPS_VW
 WHERE STEP_VTD < SYSDATE
;



/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_DONE_STEPS_VW AS
/*============================================================================================*/
SELECT ID
     , WORKFLOW_ID
     , STEP_CODE
  FROM TODO_STEPS
 WHERE NVL( DONE_FLAG, 0 ) = 1;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_OPEN_STEPS_VW AS
/*============================================================================================*/
SELECT STEP_ID      as ID
     , WORKFLOW_ID
  FROM TODO_STEPS_VW
 WHERE STEP_VTD                 >= SYSDATE 
   AND NVL( STEP_DONE_FLAG, 0 )  = 0
   AND F_LISTS_ARE_DIFFER( STEP_PRIOR_STEP_CODES
                         , F_SELECT_ROWS_TO_CSV( 'select STEP_CODE FROM TODO_DONE_STEPS_VW where WORKFLOW_ID='||WORKFLOW_ID,':' )  ) = 0                      
;



/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_PASSED_STEPS_VW AS
/*============================================================================================*/
SELECT ID
     , WORKFLOW_ID
  FROM TODO_STEPS
 WHERE ID IN ( SELECT ID FROM TODO_EXPIRED_STEPS_VW )
    OR ID IN ( SELECT ID FROM TODO_DONE_STEPS_VW    )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_OPEN_WORKFLOWS_VW AS
/*============================================================================================*/
SELECT ID
  FROM TODO_WORKFLOWS TW
 WHERE EXISTS ( SELECT 1 FROM TODO_OPEN_STEPS_VW TS WHERE TS.WORKFLOW_ID = TW.ID )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_CLOSED_WORKFLOWS_VW AS
/*============================================================================================*/
SELECT ID
  FROM TODO_WORKFLOWS TW
 WHERE NOT EXISTS ( SELECT 1 FROM TODO_OPEN_STEPS_VW TS WHERE TS.WORKFLOW_ID = TW.ID )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_MY_TODOS_VW AS
/*============================================================================================*/
SELECT WORKFLOW_CODE
     , WORKFLOW_NAME
     , WORKFLOW_DESCRIPTION
     , WORKFLOW_REMARK
     , WORKFLOW_ID
     , WORKFLOW_SUBJECT
     , WORKFLOW_VTD
     , WORKFLOW_CREATED_AT
     , WORKFLOW_CREATED_BY
     , STEP_ID
     , STEP_CODE
     , STEP_NAME
     , STEP_DESCRIPTION
     , STEP_PRIOR_STEP_CODES
     , STEP_USER_GROUP_CODE
     , STEP_REMARK
     , STEP_DONE_FLAG
     , STEP_DONE_DATE
     , STEP_DONE_USER_NAME
     , STEP_SUBJECT
     , STEP_VTD
  FROM TODO_STEPS_VW           TS
     , TODO_USERS_AND_GROUPS   UG
 WHERE UG.USER_GROUP_CODE = TS.STEP_USER_GROUP_CODE
   AND UG.USER_NAME       = NVL( V( 'APP_USER' ), USER )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_MY_OPEN_TODOS_VW AS
/*============================================================================================*/
SELECT *
  FROM TODO_MY_TODOS_VW
 WHERE STEP_ID IN ( SELECT ID FROM TODO_OPEN_STEPS_VW )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_MY_DONE_TODOS_VW AS
/*============================================================================================*/
SELECT *
  FROM TODO_MY_TODOS_VW
 WHERE STEP_ID IN ( SELECT ID FROM TODO_DONE_STEPS_VW )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_MY_EXPIRED_TODOS_VW AS
/*============================================================================================*/
SELECT *
  FROM TODO_MY_TODOS_VW
 WHERE STEP_ID IN ( SELECT ID FROM TODO_EXPIRED_STEPS_VW )
;


/*============================================================================================*/
CREATE OR REPLACE VIEW TODO_MY_PASSED_TODOS_VW AS
/*============================================================================================*/
SELECT *
  FROM TODO_MY_TODOS_VW
 WHERE STEP_ID IN ( SELECT ID FROM TODO_PASSED_STEPS_VW )
;



Prompt *****************************************************************
Prompt **                   P R O C E D U R E S                       **
Prompt *****************************************************************

/*============================================================================================*/
create or replace function TODO_NEW_WORKFLOW ( I_WORKFLOW_CODE  in varchar2
                                             , I_SUBJECT        in varchar2  := null
                                             , I_VTD            in date      := null
                                             ) return number is
/*============================================================================================*/
    V_TODO_WORKFLOW     TODO_WORKFLOWS%rowtype;
    V_TODO_STEP         TODO_STEPS%rowtype;
    V_VTD_IN_DAYS       number;
begin
    select VTD_IN_DAYS into V_VTD_IN_DAYS from TODO_WORKFLOW_TEMPLATES where CODE = I_WORKFLOW_CODE;
    V_TODO_WORKFLOW.ID              := TODO_SEQ_ID.nextval;
    V_TODO_WORKFLOW.WORKFLOW_CODE   := I_WORKFLOW_CODE;
    V_TODO_WORKFLOW.SUBJECT         := I_SUBJECT;
    V_TODO_WORKFLOW.VTD             := nvl( I_VTD, sysdate + V_VTD_IN_DAYS );
    insert into TODO_WORKFLOWS values V_TODO_WORKFLOW;

    for L_R in ( select * from TODO_STEP_TEMPLATES where WORKFLOW_CODE = I_WORKFLOW_CODE )
    loop

        V_TODO_STEP.ID              := TODO_SEQ_ID.nextval;
        V_TODO_STEP.WORKFLOW_ID     := V_TODO_WORKFLOW.ID;
        V_TODO_STEP.STEP_CODE       := L_R.CODE;
        V_TODO_STEP.SUBJECT         := I_SUBJECT;
        insert into TODO_STEPS values V_TODO_STEP;

    end loop

    commit;
    return V_TODO_WORKFLOW.ID;
end;
/



/*============================================================================================*/
create or replace procedure TODO_DROP_WORKFLOW ( I_WORKFLOW_ID in number ) is
/*============================================================================================*/
begin
    delete TODO_STEPS     where WORKFLOW_ID = I_WORKFLOW_ID;
    delete TODO_WORKFLOWS where ID          = I_WORKFLOW_ID;
end;
/

