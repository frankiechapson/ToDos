# ToDo and Checklist Manager

## Oracle SQL and PL/SQL solution to manage ToDo lists


## Why?

Creating and handling to do lists (check lists) is a typical and normal task in a company.  
Instead of using paper based check lists, here is one Oracle based implementation.

## How?
In nutshell, we can create workflow and workflow step templates, and from these templates we can generate real workflows and workflow steps (ToDos).
It is not too usable without a GUI, but we can create a user friendly UI in APEX too.  
I enclosed some screen shots about my user reports and forms.

We can order responsible group to a step (todo). The users can belong to responsible groups.
An open ToDo will appear for every users who belongs to the responsible group of the Step (ToDo).
Anyone of them can do the thing, what have to (described in the step), and check out the "Done". 
The "Done" Step will disappear from all responsibles' lists.

It uses **PKG_DIFF** package and **F_SELECT_ROWS_TO_CSV** function! So you have to download them as well.

<p/>

## Tables and its columns

<p/>

**TODO_USER_GROUPS**  
A simple „code” table for Responsible Groups. 

<p/>

  
**TODO_USERS_AND_GROUPS**  
This table connects the users to the responsible groups (or vice versa).

<p/>

**TODO_WORKFLOW_TEMPLATES**
- CODE - because it is more readable than a number
- NAME - Name of the workflow. Eg: *entering a new customer*
- VTD_IN_DAYS - A number. The workflow will be valid until (creation date + VTD_IN_DAYS). After that it will be expired, and its steps will disappear from todo lists of users. This is the default only. We can overwrite the end date of validity at the workflow creation.
- DESCRIPTION - A detailed explanation of the workflow.
 
<p/>

**TODO_STEP_TEMPLATES**
* CODE - because it is more readable than a number   
* WORKFLOW_CODE - a reference to the Workflow Template
* NAME - To Do in the step in shortly
* VTD_IN_DAYS - Validity in days. The real validity date will calculate from the workflow creation date or the last done date if the step has prior steps. The calculated validitiy can not greater than the validity date of the workflow. LEAST( NVL( MAX( DONE_DATE + VTD_IN_DAYS )of its PRIOR_TODO_STEPS ) , its WORKFLOW VTD ) , its WORKFLOW VTD )
* PRIOR_STEP_CODES - The prior step codes separated by ":" eg: "ACCOUNT:DESKTOP:WORSPACE". If a step has prior steps, that will not appear until all the prior steps have done (checked out)
* USER_GROUP_CODE - The code of the responsible (user) group 
* DESCRIPTION - A detailed explanation of the step (ToDo)

<p/>

**TODO_WORKFLOWS**
* ID - Internal ID
* WORKFLOW_CODE - Reference to the source Workflow template
* SUBJECT - The subject of the certain workflow (copy). For example the most important data of the customer, employee, product etc what we want to enter, create or doing something with it.
* VTD - The calculated or set end date of validity of the workflow. After this date the worflow will be expired.
* REMARK - The creator can add some remark to the certain workflow.
* CREATED_AT - date of creation. The base point of validity calculations.
* CREATED_BY - the user who created the workflow

<p/>

**TODO_STEPS**
* ID - Internal ID
* WORKFLOW_ID - Reference to the parent workflow
* STEP_CODE - Reference to the source Step template
* DONE_FLAG - The responsable users have to set this to 1 when done the ToDo (described in "Name" and "Description" of the Step Template and for the "Subject" of this Step)
* DONE_DATE - Date of Done
* DONE_USER_NAME - Who done it
* SUBJECT - The Subject of the Step. After workflow creation every steps' subject will be the same, the subject of the workflow. But we can change it, because we have this possibility.
* REMARK - The user who checked it out, can add some comment to it. eg: I've done it, but I did not enjoy it. :-)



## Views

* **TODO_TEMPLATES_VW** - combination of TODO_WORKFLOW_TEMPLATES and TODO_STEP_TEMPLATES                
* **TODO_WORKFLOWS_VW** - combination of TODO_WORKFLOW_TEMPLATES and TODO_WORKFLOWS 
* **TODO_EXPIRED_WORKFLOWS_VW** - ID of TODO_WORKFLOWS where VTD < SYSDATE
* **TODO_STEPS_VW** - combination of TODO_WORKFLOW_TEMPLATES, TODO_STEP_TEMPLATES, TODO_WORKFLOWS and TODO_STEPS. This is the most complex and most important view in the solution.
* **TODO_EXPIRED_STEPS_VW** - STEP_ID and WORKFLOW_ID of TODO_STEPS_VW where STEP_VTD < SYSDATE
* **TODO_DONE_STEPS_VW** - TODO_STEPS where DONE_FLAG = 1
* **TODO_OPEN_STEPS_VW** -  STEP_ID and WORKFLOW_ID of TODO_STEPS_VW where STEP_VTD >= SYSDATE, have not DONE and every prior steps have DONE (if exist any)
* **TODO_OPEN_WORKFLOWS_VW** - TODO_WORKFLOWS where exist any TODO_OPEN_STEPS_VW
* **TODO_CLOSED_WORKFLOWS_VW** - TODO_WORKFLOWS where not exist any TODO_OPEN_STEPS_VW
* **TODO_MY_TODOS_VW** - TODO_STEPS_VW where I act as an responsible
* **TODO_MY_OPEN_TODOS_VW** - TODO_MY_TODOS_VW what are open
* **TODO_MY_DONE_TODOS_VW** - TODO_MY_TODOS_VW what are done
* **TODO_MY_EXPIRED_TODOS_VW** - TODO_MY_TODOS_VW what are expired
* **TODO_MY_PASSED_TODOS_VW** - TODO_MY_TODOS_VW what are expired or done


## Codes

**TODO_NEW_WORKFLOW** function


Creates a workflow and its steps from a template defined by **I_WORKFLOW_CODE** parameter. The workflow and its steps subject will be **I_SUBJECT**. The end date of workflow validity will be **I_VTD**, and in case it is null then creation date + vtd in days of the workflow template record.  
It returns with the **ID** of the created workflow.


**TODO_DROP_WORKFLOW** procedure


Delete the steps and the workflow itself defined by **I_WORKFLOW_ID** parameter.



