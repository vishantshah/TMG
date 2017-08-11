/************************************************************************************
Class Name   : CaseCommentsController
Author       : Mantas Grigaliunas
Created Date : 15/08/2016
Function     : CaseComments component controller
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer          Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Michal Szewczyk    05/10/2016 - changes to fix malfunction
* Pawel Chrzanowski  20/10/2016   Modified saveNewComment()
*************************************************************************************/
public class CaseCommentsController {

    public String thisCaseId { get; set; }
    public List<CaseComment> allCaseComments { get; set; }

    public String orderBy { get; set; }
    public Boolean isDesc { get; set; }
    public Integer maxNumberOfComments { get; set; }
    public Integer numberOfCommentsToDisplay { get; set; }
    public Boolean showCountPanel { get; set; }
    public Boolean showMessage { get; set; }

    public CaseComment newComment { get; set; }
    public Boolean showNewComment { get; set; }
    public Boolean buttonNewClicked { get; set; }
    public String caseCommentTxt {get;set;}
    public String commandLinkLabel { 
        get{ return (showAll ? Label.Show_Less : Label.Show_More); } 
        set{ commandLinkLabel = value; } 
    }
    @TestVisible 
    private Boolean showAll = false;
    //private Boolean buttonNewClicked = false;

    /************************************************************************************
    Method Name  : getOutboundCallSettings
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Function     : Method to define based on the passed parameters in attributes and 
                   return the list of comments related to specific case.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public CaseCommentsController(){
        buttonNewClicked = false;
        showNewComment = false;
    }

    public Boolean getShowData(){
        Integer caseNum = [SELECT count() FROM CaseComment WHERE ParentId = :thisCaseId];
        
        return caseNum > 0;
    }

    public Boolean getInitState(){
        if(buttonNewClicked){
            return true;
        } else {
            showNewComment = false;
            return true;
        }
    }

    public List<CaseComment> getCaseComments(){
        try{
            showMessage = false;
            if(orderBy.equals(Constants.CASE_COMMENT_ORDERBY_DEFAULT_FIELD_NAME) 
                || GlobalQueries.getFieldsForObject(Constants.CASE_COMMENT_OBJECT_NAME).contains(orderBy.toLowerCase())){
                String caseCommentsQuery = 'SELECT Id, CommentBody, CreatedById, CreatedDate FROM CaseComment WHERE ParentId = :thisCaseId';
                if(orderBy != null)             caseCommentsQuery += ' ORDER BY ' + orderBy;
                if(isDesc)                      caseCommentsQuery += ' DESC';
                if(maxNumberOfComments != null) caseCommentsQuery += ' LIMIT ' + String.valueOf(maxNumberOfComments);
                allCaseComments = new List<CaseComment>();
                allCaseComments = Database.query(caseCommentsQuery);
            } else {
                showMessage = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Wrong_Case_Comment_Field));
                return null;
            }

            if(!showAll){
                if(allCaseComments.size() > numberOfCommentsToDisplay){

                    showCountPanel = true;
                    List<CaseComment> caseCommentsList = new List<CaseComment>();
                    for(Integer i = 0; i < numberOfCommentsToDisplay; i++){
                        caseCommentsList.add(allCaseComments[i]);
                    }
                    return caseCommentsList;

                } else { 
                    showCountPanel = false;
                    return allCaseComments;
                }

            } else {
                if(allCaseComments.size() <= numberOfCommentsToDisplay) showCountPanel = false;
                else showCountPanel = true;
                return allCaseComments;
            }

        } catch(Exception e){
            showMessage = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Case Comments Exception: ' + e.getMessage()));
            return null;
        }
    }

    /************************************************************************************
    Method Name  : createNewComment
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Function     : Metthod to create a new case instance after clicking [New Comment]
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void createNewComment(){
        showNewComment = true;
        buttonNewClicked = true;

        newComment = new CaseComment();
    }

    /************************************************************************************
    Method Name  : clearFlags
    Author       : Michal Szewczyk
    Created Date : 06/10/2016
    Function     : Metthod to clear flags
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void clearFlags(){
        showNewComment = false;
        buttonNewClicked = false;
    }
    /************************************************************************************
    Method Name  : saveNewComment
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Function     : Method to save a new comment, related to the specified case, to database 
                   after clicking [Save Comment] and reset all variables
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    Pawel Chrzanowski   20/10/2016   Added blank validation
    *************************************************************************************/
    public void saveNewComment(){
        if(String.isBlank(caseCommentTxt)){
            showMessage = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, String.format(Label.OC_Blank_Field, new List<String>{CaseComment.sObjectType.getDescribe().getLabel()})));
            return;
        }

        newComment.ParentId = thisCaseId;
        newComment.commentbody = caseCommentTxt;
        insert newComment;
        allCaseComments = null;
        getCaseComments();
    }

    /************************************************************************************
    Method Name  : cancelSaveNewComment
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void cancelSaveNewComment(){
        buttonNewClicked = false;
        showNewComment = false;
    }

    /************************************************************************************
    Method Name  : getCommentsCount
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Function     : Returns a string with record count i.e. Showing 5 out of 10 |
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public String getCommentsCount(){
        return 
            'Showing '
            + (showAll ? allCaseComments.size() : numberOfCommentsToDisplay) 
            + ' out of ' + allCaseComments.size() + ' | ';
    }

    /************************************************************************************
    Method Name  : showHideAll
    Author       : Mantas Grigaliunas
    Created Date : 15/08/2016
    Function     : Method used to show or hide all records based on set value
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void showHideAll(){
        if(!showAll) showAll = true;
        else showAll = false;
    }
}