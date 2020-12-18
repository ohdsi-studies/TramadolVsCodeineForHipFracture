#' Plot the effect of the calibration
#'
#' @description
#' \code{plotCalibrationEffect} creates a plot showing the effect of the calibration.
#'
#' @details
#' Creates a plot with the effect estimate on the x-axis and the standard error on the y-axis.
#' Negative controls are shown as blue dots, positive controls as yellow diamonds. The area below the
#' dashed line indicated estimates with p < 0.05. The orange area indicates estimates with calibrated
#' p < 0.05.
#'
#' @param logRrNegatives     A numeric vector of effect estimates of the negative controls on the log
#'                           scale.
#' @param seLogRrNegatives   The standard error of the log of the effect estimates of the negative
#'                           controls.
#' @param logRrPositives     Optional: A numeric vector of effect estimates of the positive controls on the log
#'                           scale.
#' @param seLogRrPositives   Optional: The standard error of the log of the effect estimates of the positive
#'                           controls.
#' @param null               An object representing the fitted null distribution as created by the
#'                           \code{fitNull} or \code{fitMcmcNull} functions. If not provided, a null 
#'                           will be fitted before plotting.
#' @param alpha              The alpha for the hypothesis test.                         
#' @param xLabel             The label on the x-axis: the name of the effect estimate.
#' @param title              Optional: the main title for the plot
#' @param showCis            Show 95 percent credible intervals for the calibrated p = alpha boundary.
#' @param fileName           Name of the file where the plot should be saved, for example 'plot.png'.
#'                           See the function \code{ggsave} in the ggplot2 package for supported file
#'                           formats.
#'
#' @return
#' A Ggplot object. Use the \code{ggsave} function to save to file.
#'
#' @examples
#' data(sccs)
#' negatives <- sccs[sccs$groundTruth == 0, ]
#' positive <- sccs[sccs$groundTruth == 1, ]
#' plotCalibrationEffect(negatives$logRr, negatives$seLogRr, positive$logRr, positive$seLogRr)
#'
#' @export
#' 
#' 
logRrtoSE <- function(logRr, alpha, mu, sigma) {
  phi <- (mu - logRr)^2/qnorm(alpha/2)^2 - sigma^2
  phi[phi < 0] <- 0
  se <- sqrt(phi)
  return(se)
}


plotCalibrationEffectWoutCCI <- function(logRrNegatives,
                                         seLogRrNegatives,
                                         logRrPositives = NULL,
                                         seLogRrPositives = NULL,
                                         null = NULL,
                                         alpha = 0.05,
                                         xLabel = "Relative risk",
                                         title,
                                         showCis = FALSE,
                                         fileName = NULL) {
  if (is.null(null)) {
    if (showCis) {
      null <- fitMcmcNull(logRrNegatives, seLogRrNegatives)
    } else {
      null <- fitNull(logRrNegatives, seLogRrNegatives)
    }
  }
  if (showCis && is(null, "null"))
    stop("Cannot show credible intervals when using asymptotic null. Please use 'fitMcmcNull' to fit the null")
  
  x <- exp(seq(log(0.25), log(10), by = 0.01))
  if (is(null, "null")) {
    y <- logRrtoSE(log(x), alpha, null[1], null[2])
  } else {
    chain <- attr(null, "mcmc")$chain
    matrix <- apply(chain, 1, function(null) logRrtoSE(log(x), alpha, null[1], 1/sqrt(null[2])))
    ys <- apply(matrix, 1, function(se) quantile(se, c(0.025, 0.50, 0.975), na.rm = TRUE))
    rm(matrix)
    y <- ys[2, ]
    yLb <- ys[1, ]
    yUb <- ys[3, ]
  }
  seTheoretical <- sapply(x, FUN = function(x) {
    abs(log(x))/qnorm(1 - alpha/2)
  })
  breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 12)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 12, hjust = 1)
  plot <- ggplot2::ggplot(data.frame(x, y, seTheoretical),
                          ggplot2::aes(x = x, y = y),
                          environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 1) +
    #ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5),
    #                   color = rgb(1, 0.5, 0),
    #                   size = 1,
    #                   alpha = 0.5)
  
  if (showCis) {
    plot <- plot +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = yLb,
                                        ymax = yUb), fill = rgb(0.8, 0.2, 0.2), alpha = 0.3) +
      ggplot2::geom_line(ggplot2::aes(y = yLb),
                         colour = rgb(0.8, 0.2, 0.2, alpha = 0.2),
                         size = 1) +
      ggplot2::geom_line(ggplot2::aes(y = yUb),
                         colour = rgb(0.8, 0.2, 0.2, alpha = 0.2),
                         size = 1)
  }
  plot <- plot +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5) +
    ggplot2::geom_point(shape = 16,
                        ggplot2::aes(x, y),
                        data = data.frame(x = exp(logRrNegatives), y = seLogRrNegatives),
                        size = 2,
                        alpha = 0.5,
                        color = rgb(0, 0, 0.8)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous(xLabel,
                                trans = "log10",
                                limits = c(0.25, 10),
                                breaks = breaks,
                                labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error") +
    ggplot2::coord_cartesian(ylim = c(0, 1.5)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   legend.key = ggplot2::element_blank(),
                   plot.title = ggplot2::element_text(hjust = 0.5),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "none")
  if (!missing(logRrPositives)) {
    plot <- plot + ggplot2::geom_point(shape = 23,
                                       ggplot2::aes(x, y),
                                       data = data.frame(x = exp(logRrPositives),
                                                         y = seLogRrPositives),
                                       size = 4,
                                       fill = rgb(1, 1, 0),
                                       alpha = 0.8)
  }
  if (!missing(title)) {
    plot <- plot + ggplot2::ggtitle(title)
  }
  if (!is.null(fileName))
    ggplot2::ggsave(fileName, plot, width = 6, height = 4.5, dpi = 400)
  return(plot)
}