#'Make Powerpoint List for ROC curve Analysis
#'@param yvar Name of dependent variable
#'@param xvars Names of independent variables
#'@param dataname Name of data
#'@param multiple logical Whether or not analyze as multiple predictor model
#'@param separate logical Whether or not plot independent variables separately
#'@param vanilla logical Whether or not make vanilla table
#'@param show.line,show.points,show.eta,show.sens,show.AUC logical Arguments to be passed to plot_ROC()
#'@export
#'@examples
#'require(moonBook)
#'require(ggplot2)
#'require(multipleROC)
#'result=makePPTxList_ROC()
#'result=makePPTxList_ROC(multiple=TRUE)
makePPTxList_ROC=function(yvar="male",xvars=c("weight","height","age"),dataname="radial",
                          multiple=FALSE,separate=TRUE,vanilla=TRUE,show.line=FALSE,
                          show.points=TRUE,show.eta=TRUE,show.sens=TRUE,
                          show.AUC=TRUE){

     # yvar="male";xvars=c("weight","height","age");dataname="radial"
     # multiple=TRUE;separate=TRUE
     no=length(xvars)
     if(multiple){

          formula=paste0(yvar,"~",paste0(xvars,collapse="+"))
          title="ROC Curve Analysis"
          type="ggplot"
          code=paste0("step_ROC(",formula,",data=",dataname,",plot=TRUE",
                      ",show.points=",show.points,
                      ",show.eta=",show.eta,
                      ",show.sens=",show.sens,
                      ",show.AUC=",show.AUC,
                      ")")
          title=c(title,"Stepwise Regression")
          type=c(type,"Rcode")
          code=c(code,paste0("anovaTable(step_ROC(",formula,",data=",dataname,",plot=FALSE,trace=1))"))
          title=c(title,"Analysis of Deviance Table")
          type=c(type,"table")
          code=c(code,paste0("anovaTable(step_ROC(",formula,",data=",dataname,",plot=FALSE),vanilla=",vanilla,")"))
     } else{
          title="ROC Curve Analysis"
          type="ggplot"
          temp=paste0(xvars,collapse="','")
          code=paste0("plot_ROC2(yvar='",yvar,"',xvars=c('",temp,"'),dataname='",dataname,"'",
                      ",show.points=",show.points,
                      ",show.eta=",show.eta,
                      ",show.sens=",show.sens,
                      ",show.AUC=",show.AUC,")")
          if(separate){
               for(i in 1:no){
                  title=c(title,paste(yvar,"by",xvars[i]))
                  type=c(type,"ggplot")
                  temp=paste0("plot_ROC(multipleROC(form=",yvar,"~",xvars[i],",data=",dataname,",plot=FALSE)",
                              ",show.points=",show.points,
                              ",show.eta=",show.eta,
                              ",show.sens=",show.sens,
                              ",show.AUC=",show.AUC,")")
                  code=c(code,temp)
               }
          }
     }
     data.frame(title=title,type=type,code=code,stringsAsFactors = FALSE)
}
