#' Calculate area under curve
#' @param df A data.frame Result of calSens()
#' @return A numeric of area under curve
#' @export
simpleAUC <- function(df){
     df=df[order(df$x,decreasing=TRUE),]
     TPR=df$sens
     FPR=df$fpr

     dFPR <- c(diff(FPR), 0)
     dTPR <- c(diff(TPR), 0)

     sum(TPR * dFPR) + sum(dTPR * dFPR)/2
}



#' Calculate sensitivity, specificity
#' @param x A numeric vector as a predictor
#' @param y A numeric vector as a result
#' @importFrom purrr map_dfr
#' @export
#' @examples
#' require(moonBook)
#' calSens(radial$height,radial$male)
#' @return
#' A data.frame
calSens=function(x,y){
     newx=sort(c(unique(x),max(x,na.rm=TRUE)+1))
     completeTable=function(res){
          if(nrow(res)==1){
               res1=matrix(c(0,0),nrow=1)
               temp=setdiff(c("TRUE","FALSE"),attr(res,"dimnames")[[1]][1])
               if(temp=="FALSE") res=rbind(res1,res)
               else res=rbind(res,res1)
               res
          }
          res
     }

     getSens=function(cut){
          res=table(x>=cut,y)
          res=completeTable(res)
          sens=res[2,2]/sum(res[,2])
          spec=res[1,1]/sum(res[,1])
          ppv=res[2,2]/sum(res[2,])
          npv=res[1,1]/sum(res[1,])
          data.frame(x=cut,sens=sens,spec=spec,fpr=1-spec,ppv=ppv,npv=npv,sum=sens+spec)
     }
     map_dfr(newx,function(cut){getSens(cut)})
}



#' Do a ROC Curve Analysis
#'
#' @aliases plot.multipleROC
#'
#' @param formula A formula
#' @param data A data.frame
#' @param plot logical Whether or not draw plot
#' @export
#' @examples
#' multipleROC(am~wt,data=mtcars)
#' @return A list of class of multipleROC with elements
#' \item{fit}{A class of glm}
#' \item{df}{a data.frame}
#' \item{cutpoint}{Numeric. cutpoint}
#' \item{sens}{label with sensitivity, specificity}
#' \item{auc}{numeric. area under curve value}
#' \item{cutoff}{A data.fame with best cutoff value(s)}
multipleROC=function(formula,data,plot=TRUE){
     fit=glm(formula,data=data,family="binomial")
     df=calSens(fit$fitted.values,fit$y)
     no=which.max(df$sum)
     cutpoint=df$x[no]
     sens=paste("Sens:",sprintf("%03.1f",df[no,]$sens*100),"%\n",
                "Spec:",sprintf("%03.1f",df[no,]$spec*100),"%\n",
                "PPV:",sprintf("%03.1f",df[no,]$ppv*100),"%\n",
                "NPV:",sprintf("%03.1f",df[no,]$npv*100),"%\n",
                sep="")
     auc=simpleAUC(df)
     cutoff=fit$model[which(fit$fitted==cutpoint),][-1]
     result=list(
          fit=fit,
          df=df,
          cutpoint=cutpoint,
          sens=sens,
          auc=auc,
          cutoff=cutoff
     )
     class(result)="multipleROC"
     if(plot) print(plot(result))
     invisible(result)
}

#'@rdname multipleROC
#'@method plot multipleROC
#'@param x \code{multipleROC}
#'@param ... Further arguments to be passed to plot_ROC
#'@export
plot.multipleROC=function(x,...){
     plot_ROC(x,...)
}




#'Calculate x, y coordinate for ROC curve
#' @param x An object of class multipleROC
#' @param no Integer
#' @return A data.frame
#' @export
#' @examples
#' x=multipleROC(form=am~wt,data=mtcars)
#' makeCoord(x)
makeCoord=function(x,no=1){
     df=data.frame(x=x$df$fpr,y=x$df$sens)
     df=df[order(df$y),]
     df$no=no
     df
}


#' Convert A list from ROC() to roc object
#' @param x An object of class multipleROC
#' @importFrom pROC roc
#'@export
multipleROC2roc=function(x){
     pROC::roc(x$fit$y,x$fit$fitted.values,ci=T)
}


#' Make labels for ROC curve
#' @param x An object of class multipleROC
#' @param no Integer
#' @return A data.frame
#' @importFrom stats wilcox.test
#' @importFrom pROC ci
#' @export
#' @examples
#' x=multipleROC(am~wt,data=mtcars)
#' makeLabels(x)
makeLabels=function(x,no=1){
     eta=paste0("lr.eta= ",round(x$cutpoint,3))

     sens=x$sens
     max=max(x$df$sum)
     legend=paste("Model: ",colnames(x$fit$model)[1],"~",
                  paste(colnames(x$fit$model)[-1],collapse="+"),sep="")

     cut=paste0(x$cutoff[1,],collapse=",")
     temp=round(x$auc,3)
     if(ncol(x$fit$model)==2){
          ci=suppressMessages(ci(multipleROC2roc(x)))
          temp=paste(temp,"(",round(ci[1],3),"-",round(ci[3],3),")",sep="")
          temp
          if(!is.numeric(x$fit$model[,1])) y=as.numeric(x$fit$model[,1])
          else y=as.numeric(x$fit$model[,1])
          result=wilcox.test(x$fit$model[,2],y)
          if(result$p.value<0.001) {
               temp=paste(temp,", p < 0.001")
          } else temp=paste(temp,", p =",round(result$p.value,3))
     } else{
             ci=suppressMessages(ci(multipleROC2roc(x)))
             temp=paste(temp,"(",round(ci[1],3),"-",round(ci[3],3),")",sep="")
             temp
             result=wilcox.test(x$fit$fitted.values,x$fit$y)
             if(result$p.value<0.001) {
                     temp=paste(temp,", p < 0.001")
             } else temp=paste(temp,", p =",round(result$p.value,3))
             temp
     }
     labelAUC= paste(legend,"\nOptimal Cutoff value: ",cut,"\n","AUC: ",temp )
     i=which.max(x$df$sum)
     xx=x$df$fpr[i]
     yy=x$df$sens[i]
     ypos=no*0.11-0.05
     data.frame(x=xx,y=yy,max,eta,sens,no,labelAUC,ypos)
}



#' Draw ROC curve with variable names
#' @param yvar Name of dependent variable
#' @param xvars Names of independent variables
#' @param dataname Name of data
#' @param ... Further arguments to be passed to plot_ROC
#' @export
#' @examples
#' require(moonBook)
#' plot_ROC2(yvar="male",xvars=c("weight","height","age"),dataname="radial")
plot_ROC2=function(yvar,xvars,dataname,...){
        x=lapply(xvars,function(x){
                formula=paste0(yvar,"~",x)
                eval(parse(text=paste0("multipleROC(form=",formula,",data=",dataname,",plot=FALSE)")))
        })
        plot_ROC(x,...)
}


#'Draw ROC curves
#'@param x A list of class multipleROC
#'@param show.points logical
#'@param show.eta logical
#'@param show.sens logical
#'@param show.AUC logical
#'@param facet logical
#'@importFrom purrr map2_dfr
#'@importFrom ggplot2 ggplot aes_string geom_line geom_segment geom_text annotate labs
#'@importFrom ggplot2 theme_bw theme geom_point facet_wrap
#'@importFrom pROC roc.test
#'@export
#'@return A ggplot
#'@examples
#'require(moonBook)
#'a=multipleROC(male~height,data=radial)
#'plot(a)
#'b=multipleROC(male~age,data=radial)
#'plot_ROC(list(a,b))
#'c=multipleROC(form=male~weight,data=radial)
#'plot_ROC(list(a,b,c),show.eta=FALSE,show.sens=FALSE)
#'plot_ROC(list(a,b,c),facet=TRUE)
#'require(ggplot2)
#'plot_ROC(list(a,b,c))+facet_grid(no~.)
plot_ROC=function(x,show.points=TRUE,show.eta=TRUE,show.sens=TRUE,show.AUC=TRUE,facet=FALSE){


     if("multipleROC" %in% class(x)) x=list(x)

     no=as.list(1:length(x))
     df=map2_dfr(x,no,makeCoord)
     df$no=factor(df$no)
     df2=suppressWarnings(map2_dfr(x,no,makeLabels))
     df2$no=factor(df2$no)
     df2
     if(length(x)==1) {
          p=ggplot(df,aes_string(x="x",y="y"))+geom_line()
     } else{
          p=ggplot(df,aes_string(x="x",y="y",group="no",color="no"))+geom_line()
     }
     p
     if(show.points) p<-p+geom_point(data=df2,pch=4,size=5)
     if(show.eta) p<-p+geom_text(data=df2,
                                    aes_string(x="x-0.01",y="y+0.02",label="eta"),hjust=1)
     if(show.sens) p<-p+geom_text(data=df2,
                                  aes_string(x="x+0.01",y="y-0.09",label="sens"), hjust=0)
     if(show.AUC)  p<-p+geom_text(data=df2,
                                  aes_string(x="0.5",y="ypos",label="labelAUC"),hjust=0)

     if(length(x)==2) {

          result=suppressWarnings(roc.test(multipleROC2roc(x[[1]]),multipleROC2roc(x[[2]])))

          result
          if(result$p.value <0.001) {
                    temp="p < 0.001"
               } else temp=paste("p = ",round(result$p.value,3),sep="")

               p<-p+annotate(geom="text",0.5,3*0.11-0.05,
                             label=paste("DeLong's test for two correlated ROC curves\n",
                                         "Z = ",round(result$statistic,3),", ",temp,sep=""),hjust=0)

     }

     p<-p+labs(x="1-Specificity",y="Sensitivity")+theme_bw()+
          geom_segment(x=0,y=0,xend=1,yend=1,lty=2)+
          theme(legend.position="none")
     if(facet) p<-p+facet_wrap(~no)
     p
}


#' Perform multiple logistic regression with stepwise
#' @param formula A formula for logistic regression
#' @param data A data.frame
#' @param plot logical If true, return a ggplot
#' @param trace if positive, information is printed during the running of step. Larger values may give more detailed information.
#' @param ... Further arguments to be passed to plot_ROC()
#' @importFrom stats glm terms na.omit step anova
#' @export
#' @return A ggplot or an object of class anova
#' @examples
#' require(moonBook)
#' step_ROC(male~weight+height+age,data=radial)
#' step_ROC(male~weight+height+age,data=radial,plot=FALSE)
step_ROC=function(formula,data,plot=TRUE,trace=0,...){
     call=paste(deparse(formula),", ","data= ",substitute(data),sep="")
     f=formula
     myt=terms(f,data=data)
     y=as.character(f[[2]])

     myvar=attr(myt,"term.labels")
     count=length(myvar)
     mydf=data[y]
     for(i in 1:count) {
          mydf=cbind(mydf,data[[myvar[i]]])
          colnames(mydf)[i+1]=myvar[i]
     }
     mydf=na.omit(mydf)
     #str(mydf)
     result=glm(formula,data=mydf)
     final=step(result,trace=trace)
     x=multipleROC(formula,data=mydf,plot=FALSE)
     #str(final$model)
     x2=multipleROC(final$formula,data=mydf,plot=FALSE)
     if(plot) {
          plot_ROC(list(x,x2),...)
     } else {
          result=anova(x2$fit,x$fit,test="Chisq")
          result
     }

}

