/**
* @author Unknown
* @date Unknown
* @description This is a helper class to facilitate XML response parsing and population of related objects from respective nodes
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         16/07/2015  //modified parseUserOrderHistoryResponse()
Wiktor Czykin   1.2         08/10/2015  //modified parseUserOrderHistoryResponse() - orders order reverse 
**/
public class MPPInterfaceHTTPHelper { 

    /** 
     * This method parses the MPP#UserServices response XML and populates MPPInterfaceHTTP.UserServicesResult elements
     * 
     * @param response      the XML response element
     * @return an instance of MPPInterfaceHTTP.UserServicesResult populated with respective fields from the nodes of the response
     */
    public static MPPInterfaceHTTP.UserServicesResult parseUserServicesResponse(Dom.Document response) {
        
        MPPInterfaceHTTP.UserServicesResult result = new MPPInterfaceHTTP.UserServicesResult();
        MPPInterfaceHTTP.ArrayOfServiceInformationResult arrServiceInfoResult = new MPPInterfaceHTTP.ArrayOfServiceInformationResult();
        
        String errorMessage, errorNumber;
        Boolean isError = false;
        
        // root element is UserServicesResult
        for(DOM.Xmlnode node : response.getRootElement().getChildElements()) {
            
            // check if the response contains any error message or not
            // if yes, populate and skip iterating further since the response contained error
            if(node.getName() == 'ErrorMessage') {
                errorMessage = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserServicesResponse() : Error Message ' + errorMessage);
            }
                
            if(node.getName() == 'ErrorNumber') {
                errorNumber = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserServicesResponse() : Error Number ' + errorNumber);
            }
            
            if((errorNumber != null && errorNumber != '') && (errorMessage != null && errorMessage != '')) {
				system.debug('MPPInterfaceHTTPHelper#parseUserServicesResponse() : Error Scenario Error Number[' + errorNumber + ']::Error Message[' +  errorMessage + ']. Throwing exception ..');
                isError = true;
                break;
            }

            /* visit ServiceInformation */          
            if(node.getName() == 'ServiceInformation') {
                for(DOM.Xmlnode serviceInfoNode : node.getChildElements()) {
                    
                    // found ServiceInformationResult child node
                    if(serviceInfoNode.getName() == 'ServiceInformationResult') {
                        MPPInterfaceHTTP.ServiceInformationResult serviceInfoRes = new MPPInterfaceHTTP.ServiceInformationResult();
                        
                        // iterate over ServiceInformationResult node
                        for(DOM.Xmlnode serviceInfoResultNode : serviceInfoNode.getChildElements()) {
                            
                            // populate the node level values
                            populateServiceInformationResult(serviceInfoResultNode, serviceInfoRes);

                            // found PaymentScheduleInformation  node
                            if(serviceInfoResultNode.getName() == 'PaymentScheduleInformation') {
                                MPPInterfaceHTTP.PaymentScheduleResult psResult = new MPPInterfaceHTTP.PaymentScheduleResult();

                                // iterate over PaymentScheduleInformation node
                                for(DOM.Xmlnode pymntScheduleInfoNode : serviceInfoResultNode.getChildElements()) {

                                    populatePaymentScheduleInformation(pymntScheduleInfoNode, psResult);

                                    // found ScheduleOrders node
                                    if(pymntScheduleInfoNode.getName() == 'ScheduleOrders') {
                                        MPPInterfaceHTTP.ArrayOfScheduledOrdersResult soResArray = new MPPInterfaceHTTP.ArrayOfScheduledOrdersResult();
                                        
                                        // iterate over ScheduleOrders node
                                        for(DOM.Xmlnode scheduledOrdersNode : pymntScheduleInfoNode.getChildElements()) {
                                            if(scheduledOrdersNode.getName() == 'ScheduledOrdersResult') {
                                                MPPInterfaceHTTP.ScheduledOrdersResult soResult = new MPPInterfaceHTTP.ScheduledOrdersResult();
                                                
                                                // iterate over ScheduledOrdersResult
                                                for(DOM.Xmlnode scheduledOrdersResNode : scheduledOrdersNode.getChildElements()) {
                                                    populateScheduledOrdersResult(scheduledOrdersResNode, soResult);
                                                    
                                                    // found PriceInformation node
                                                    if(scheduledOrdersResNode.getName() == 'PriceInformation') {
                                                        MPPInterfaceHTTP.TaxResult taxRes = new MPPInterfaceHTTP.TaxResult();
                                                        MPPInterfaceHTTP.ArrayOfTaxRegionAmount taxRegionAmtArray = new MPPInterfaceHTTP.ArrayOfTaxRegionAmount();

                                                        // iterate over PriceInformation
                                                        for(DOM.Xmlnode priceInformationNode : scheduledOrdersResNode.getChildElements()) {
                                                            populatePriceInformation(priceInformationNode, taxRes);
                                                            
                                                            // found TaxRegions
                                                            if(priceInformationNode.getName() == 'TaxRegions') {
                                                                // iterate over TaxRegions
                                                                for(DOM.Xmlnode taxRegionsNode : priceInformationNode.getChildElements()) {
                                                                    
                                                                    // found TaxRegionAmount
                                                                    if(taxRegionsNode.getName() == 'TaxRegionAmount') {
                                                                        // iterate over TaxRegionAmount
                                                                        for(DOM.Xmlnode taxRegionAmtNode : taxRegionsNode.getChildElements()) {
                                                                            MPPInterfaceHTTP.TaxRegionAmount taxRegAmt = new MPPInterfaceHTTP.TaxRegionAmount();
                                                                            populateTaxRegionAmount(taxRegionAmtNode, taxRegAmt);
                                                                            taxRegionAmtArray.getTaxRegionAmounts().add(taxRegAmt);
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            taxRes.taxRegions = taxRegionAmtArray;
                                                        }
                                                        soResult.priceInformation = taxRes;
                                                    }
                                                }
                                                soResArray.getScheduledOrdersResults().add(soResult);
                                            }
                                        }
                                        psResult.scheduleOrders = soResArray;
                                    }
                                }
                                serviceInfoRes.PaymentScheduleInformation = psResult;
                            }
                            
                            
                            // found SubscriptionInformation
                            if(serviceInfoResultNode.getName() == 'SubscriptionInformation') {
                                MPPInterfaceHTTP.SubscriptionResult subResult = new MPPInterfaceHTTP.SubscriptionResult();

                                // now iterate over SubscriptionInformation node
                                for(DOM.Xmlnode subsInfoNode : serviceInfoResultNode.getChildElements()) {

                                    populateSubscriptionInformation(subsInfoNode, subResult);

                                    // found LastBillingTaxResult node
                                    if(subsInfoNode.getName() == 'LastBillingTaxResult') {
                                        MPPInterfaceHTTP.TaxResult taxRes = new MPPInterfaceHTTP.TaxResult();
                                        MPPInterfaceHTTP.ArrayOfTaxRegionAmount taxRegionAmtArray = new MPPInterfaceHTTP.ArrayOfTaxRegionAmount();

                                        // iterate over LastBillingTaxResult node
                                        for(DOM.Xmlnode lastBillingTaxResNode : subsInfoNode.getChildElements()) {
                                            
                                            populatLastBillingTaxResult(lastBillingTaxResNode, taxRes);
                                            
                                            // found TaxRegions
                                            if(lastBillingTaxResNode.getName() == 'TaxRegions') {
                                                // iterate over TaxRegions
                                                for(DOM.Xmlnode taxRegionsNode : lastBillingTaxResNode.getChildElements()) {
                                                    
                                                    // found TaxRegionAmount
                                                    if(taxRegionsNode.getName() == 'TaxRegionAmount') {
                                                        // iterate over TaxRegionAmount
                                                        for(DOM.Xmlnode taxRegionAmtNode : taxRegionsNode.getChildElements()) {
                                                            MPPInterfaceHTTP.TaxRegionAmount taxRegAmt = new MPPInterfaceHTTP.TaxRegionAmount();
                                                            populateTaxRegionAmount(taxRegionAmtNode, taxRegAmt);
                                                            taxRegionAmtArray.getTaxRegionAmounts().add(taxRegAmt);
                                                        }
                                                    }
                                                }
                                                taxRes.taxRegions = taxRegionAmtArray;
                                            }
                                        }
                                        subResult.lastBillingTaxResult = taxRes;
                                    }
                                    
                                    // found SubscriptionPriceItems node
                                    if(subsInfoNode.getName() == 'SubscriptionPriceItems') {
                                        MPPInterfaceHTTP.SubscriptionPriceItems subsPriceItems = new MPPInterfaceHTTP.SubscriptionPriceItems();
                                        MPPInterfaceHTTP.ArrayOfSubscriptionPriceItem subsPriceItemArray = new MPPInterfaceHTTP.ArrayOfSubscriptionPriceItem();
                                        
                                        // iterate over SubscriptionPriceItems node
                                        for(DOM.Xmlnode subsPriceItemNode : subsInfoNode.getChildElements()) {
                                            // found Items
                                            if(subsPriceItemNode.getName() == 'Items') {
                                                // iterate over Items
                                                for(DOM.Xmlnode itemsNode : subsPriceItemNode.getChildElements()) {
                                                    // found SubscriptionPriceItem
                                                    if(itemsNode.getName() == 'SubscriptionPriceItem') {
                                                        // iterate over SubscriptionPriceItem
                                                        for(DOM.Xmlnode subsPriceNode : itemsNode.getChildElements()) {
                                                            MPPInterfaceHTTP.SubscriptionPriceItem subsPriceItem = new MPPInterfaceHTTP.SubscriptionPriceItem();
                                                            populateSubscriptionPriceItem(subsPriceNode, subsPriceItem);
                                                            subsPriceItemArray.getSubscriptionPriceItems().add(subsPriceItem);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        subsPriceItems.setItems(subsPriceItemArray);
                                    }
                                }
                                serviceInfoRes.SubscriptionInformation = subResult;
                            }
                        } 
                        arrServiceInfoResult.getServiceInformationResults().add(serviceInfoRes);
                    }
                }
                result.serviceInformation = arrServiceInfoResult;
            }
        }
        
        if(isError) {
            throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        return result;
    }

	/**
     * Helper method to parse the MPP UserInfo XML response added as part of the subscriberConsoleWebservice
     *
     */
		public static MPPInterfaceHTTP.UserInfoResult parseUserInfoResponse (Dom.Document response) {
        
        MPPInterfaceHTTP.UserInfoResult result = new MPPInterfaceHTTP.UserInfoResult();
        
        String errorMessage, errorNumber;
        Boolean isError = false;
        
        // root element is UserInfoResult
        for(DOM.Xmlnode node : response.getRootElement().getChildElements()) {
            
            // check if the response contains any error message or not
            // if yes, populate and skip iterating further since the response contained error
            if(node.getName() == 'ErrorMessage') {
                errorMessage = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserInfoResponse() : Error Message ' + errorMessage);
            }
                
            if(node.getName() == 'ErrorNumber') {
                errorNumber = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserInfoResponse() : Error Number ' + errorNumber);
            }
            
            if((errorNumber != null && errorNumber != '') && (errorMessage != null && errorMessage != '')) {
				system.debug('MPPInterfaceHTTPHelper#parseUserInfoResponse() : Error Scenario Error Number[' + errorNumber + ']::Error Message[' +  errorMessage + ']. Throwing exception ..');
                isError = true;
                break;
            }

            /* extract AccountDetailParameters */          
            if(node.getName() == 'AccountDetailParameters') {
            	         	
            	MPPInterfaceHTTP.AccountDetailParameters[] adParamResults = new List<MPPInterfaceHTTP.AccountDetailParameters>();
            	
            	for(DOM.Xmlnode accountParameter : node.getChildElements()) {
                    populateAccountDetail(accountParameter, adParamResults);
                }
                result.AccountDetailParameters = adParamResults;
            }

            /* extract Other Parameters */          
            if(node.getName() == 'AccountStatus')
            	result.AccountStatus = node.getText();
            
            if(node.getName() == 'EmailAddress')
				result.EmailAddress = node.getText();

            if(node.getName() == 'FirstName')
				result.FirstName = node.getText();
				
            if(node.getName() == 'Surname')
				result.Surname = node.getText();

            if(node.getName() == 'Guid')
				result.MPPGuid = node.getText();				
              
        }
        
        if(isError) {
            throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        return result;
    }

    /**********************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Helper method to parse the MPP UserInfo XML response added as part of the subscriberConsoleWebservice
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/07/2015  //added escapeXML for RawOrderDescription setting as mpp is passing in html and it is failing in json parsing in javascript
    ***********************************************************************************/
	public static MPPInterfaceHTTP.UserOrderHistoryResult parseUserOrderHistoryResponse (Dom.Document response, Boolean bReverseToAscending) {
        
        MPPInterfaceHTTP.UserOrderHistoryResult result = new MPPInterfaceHTTP.UserOrderHistoryResult(); 
        
        String errorMessage, errorNumber;
        Boolean isError = false;
        
        // root element is UserOrderHistoryResult
        for(DOM.Xmlnode node : response.getRootElement().getChildElements()) {
            
            // check if the response contains any error message or not
            // if yes, populate and skip iterating further since the response contained error
            if(node.getName() == 'ErrorMessage') {
                errorMessage = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserOrderHistoryResponse() : Error Message ' + errorMessage);
            }
                
            if(node.getName() == 'ErrorNumber') {
                errorNumber = node.getText();
				system.debug('MPPInterfaceHTTPHelper#parseUserOrderHistoryResponse() : Error Number ' + errorNumber);
            }
            
            if((errorNumber != null && errorNumber != '') && (errorMessage != null && errorMessage != '')) {
				system.debug('MPPInterfaceHTTPHelper#parseUserOrderHistoryResponse() : Error Scenario Error Number[' + errorNumber + ']::Error Message[' +  errorMessage + ']. Throwing exception ..');
                isError = true;
                break;
            }
			
			/* extract OrderHistoryItems */        
            if(node.getName() == 'OrderHistoryItems') {

				MPPInterfaceHTTP.OrderHistoryItem[] retrievedOrderHistoryItems = new List<MPPInterfaceHTTP.OrderHistoryItem>();
            	//MPPInterfaceHTTP.OrderHistoryItem thisOrderHistoryItem = new MPPInterfaceHTTP.OrderHistoryItem();
            	
            	for(DOM.Xmlnode orderHistItems : node.getChildElements()) {
            		MPPInterfaceHTTP.OrderHistoryItem thisOrderHistoryItem = new MPPInterfaceHTTP.OrderHistoryItem();
	            		
            		if(orderHistItems.getName() == 'OrderHistoryItem'){
						for(DOM.Xmlnode orderHistItemDetail : orderHistItems.getChildElements()){
							if(orderHistItemDetail.getName() == 'OrderDateUTC' || orderHistItemDetail.getName() == 'OrderDate'){
								thisOrderHistoryItem.OrderDate = orderHistItemDetail.getText();
							}
								
		              		if(orderHistItemDetail.getName() == 'OrderDescription'){
								thisOrderHistoryItem.RawOrderDescription = orderHistItemDetail.getText().escapeXml();
						        //DM: Sometimes MPP stores HTML and other characters in the description that causes issues with the subscriber diagnostic console
								thisOrderHistoryItem.OrderDescription = 'Order Description values from MPP not supported at present';
		              		}
			            			
		              		if(orderHistItemDetail.getName() == 'OrderId'){
	            				thisOrderHistoryItem.OrderId = orderHistItemDetail.getText();
		              		}
			            		
		            		if(orderHistItemDetail.getName() == 'TaxResult') {
		            			for(DOM.Xmlnode taxResult : orderHistItemDetail.getChildElements()) {
		            				
			            			if(taxResult.getName() == 'GrossAmount')
			            				thisOrderHistoryItem.GrossAmount = taxResult.getText();
			            			
			            			if(taxResult.getName() == 'NetAmount')
			            				thisOrderHistoryItem.NetAmount = taxResult.getText();
		            			}
		            		}

		              		if(orderHistItemDetail.getName() == 'Currency'){
		              			thisOrderHistoryItem.OrderCurrency = orderHistItemDetail.getText();
		              		}

		              		if(orderHistItemDetail.getName() == 'PaymentType'){
		              			thisOrderHistoryItem.PaymentType = orderHistItemDetail.getText();
		              		}
		              		
		              		if(orderHistItemDetail.getName() == 'Parameters'){
		              			list<MPPInterfaceHTTP.OrderParameter> orderParameters = new list<MPPInterfaceHTTP.OrderParameter>();
		              			
		              			for(DOM.Xmlnode parmResult : orderHistItemDetail.getChildElements()) {

		              				if(parmResult.getName() == 'OrderParameter'){
		              					MPPInterfaceHTTP.OrderParameter op = new MPPInterfaceHTTP.OrderParameter();
		              					
		              					for(DOM.Xmlnode orderParmResult : parmResult.getChildElements()) {
		              						
					            			if(orderParmResult.getName() == 'ParameterName'){
					            				op.Name = orderParmResult.getText();
					            			}
					            				
					            			if(orderParmResult.getName() == 'ParameterValue')
					            				op.Value = orderParmResult.getText();
		              					}
		              					system.debug('***op: ' + op);
		              					
		              					orderParameters.add(op);
		              				}
		              			}
		              			system.debug('***orderParameters: ' + orderParameters);
		              			
		              			thisOrderHistoryItem.OrderParameters = orderParameters;
		              		}
						}
        			}
                	retrievedOrderHistoryItems.add(thisOrderHistoryItem); 
            	}

                if(!retrievedOrderHistoryItems.isEmpty() && bReverseToAscending != null && bReverseToAscending){
                    List<MPPInterfaceHTTP.OrderHistoryItem> lstReverse = new List<MPPInterfaceHTTP.OrderHistoryItem>();
                    for(Integer i = (retrievedOrderHistoryItems.size()-1); i >= 0; i--){
                        lstReverse.add(retrievedOrderHistoryItems[i]);
                    }
                    result.OrderHistoryItems = lstReverse;
                }else{
            	   result.OrderHistoryItems = retrievedOrderHistoryItems;
                }



            } 

            if(node.getName() == 'TotalNumberOfOrders')
            	result.TotalNumberOfOrders = node.getText();
        }
        system.debug('***result<OrderHistoryItem>: ' + result); 
        
        if(isError) {
            throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        return result;
    }


    /** 
     * Helper method to parse the AccountDetailParameters node in MPP response XML
     * 
     * @param      the AccountDetailParameters XML node element
     * @param      the MPPInterfaceHTTP.AccountDetailParameters object to be populated from node items
     */
    private static void populateAccountDetail(
        DOM.Xmlnode accountDetail, MPPInterfaceHTTP.AccountDetailParameters[] adParamResults) {
        
        MPPInterfaceHTTP.AccountDetailParameters thisAdParam = new MPPInterfaceHTTP.AccountDetailParameters();    
        
        for(DOM.Xmlnode accountParameterDetail : accountDetail.getChildElements()) 
        {	
            if(accountParameterDetail.getName() == 'ParameterName') {
	            thisAdParam.ParameterName = accountParameterDetail.getText();
	        }
	        if(accountParameterDetail.getName() == 'ParameterValue') {
	            thisAdParam.ParameterValue = accountParameterDetail.getText();
	        }        
        }
        adParamResults.add(thisAdParam);
    } 

    /** 
     * Helper method to parse the ServiceInformationResult node in the response XML
     * 
     * @param serviceInfoResultNode     the ServiceInformationResult XML node element
     * @param serviceInfoRes            the MPPInterfaceHTTP.ServiceInformationResult object to be populated from node items
     */
    private static void populateServiceInformationResult(
        DOM.Xmlnode serviceInfoResultNode, MPPInterfaceHTTP.ServiceInformationResult serviceInfoRes) {
        
        if(serviceInfoResultNode.getName() == 'ApplicationMessage') {
            serviceInfoRes.ApplicationMessage = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'ApplicationMessage2') {
            serviceInfoRes.ApplicationMessage2 = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'ApplicationOfferName') {
            serviceInfoRes.ApplicationOfferName = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'ExpiryDate') {
            serviceInfoRes.ExpiryDate = DateTime.valueOf(getDateTimeString(serviceInfoResultNode.getText()));
        }
        
        if(serviceInfoResultNode.getName() == 'FirstNonDiscountedBillingPoint') {
            serviceInfoRes.FirstNonDiscountedBillingPoint = DateTime.valueOf(getDateTimeString(serviceInfoResultNode.getText()));
        }
        
        if(serviceInfoResultNode.getName() == 'LastDiscountedBillingPoint') {
            serviceInfoRes.LastDiscountedBillingPoint = DateTime.valueOf(getDateTimeString(serviceInfoResultNode.getText()));
        }
        
        if(serviceInfoResultNode.getName() == 'OfferName') {
            serviceInfoRes.OfferName = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'OfferTypeId') {
            serviceInfoRes.OfferTypeId = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'PaymentMethod') {
            serviceInfoRes.PaymentMethod = getPaymentTypes(serviceInfoResultNode.getText());
        }
        
        if(serviceInfoResultNode.getName() == 'ServiceGroup') {
            serviceInfoRes.ServiceGroup = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'ServiceID') {
            serviceInfoRes.ServiceID = Integer.valueOf(serviceInfoResultNode.getText());
        }
        
        if(serviceInfoResultNode.getName() == 'ServiceStatus') {
            serviceInfoRes.ServiceStatus = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'ServiceTitle') {
            serviceInfoRes.ServiceTitle = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'VoucherCode') {
            serviceInfoRes.VoucherCode = serviceInfoResultNode.getText();
        }
        
        if(serviceInfoResultNode.getName() == 'VoucherDiscountPrice') {
            serviceInfoRes.VoucherDiscountPrice = Decimal.valueOf(serviceInfoResultNode.getText());
        }                           
    }
        
        
    /** 
     * Helper method to parse the PaymentScheduleInformation node in the response XML
     * 
     * @param pymntScheduleInfoNode     the PaymentScheduleInformation XML node element
     * @param psResult                  the MPPInterfaceHTTP.PaymentScheduleResult object to be populated from node items
     */
    private static void populatePaymentScheduleInformation(
        DOM.Xmlnode pymntScheduleInfoNode, MPPInterfaceHTTP.PaymentScheduleResult psResult) {
            
        if(pymntScheduleInfoNode.getName() == 'Frequency') {
            psResult.Frequency = pymntScheduleInfoNode.getText();
        }
    
        if(pymntScheduleInfoNode.getName() == 'PaymentDate') {
            psResult.PaymentDate = Integer.valueOf(pymntScheduleInfoNode.getText());
        }
    
        if(pymntScheduleInfoNode.getName() == 'PaymentDateOffset') {
            psResult.PaymentDateOffset = Integer.valueOf(pymntScheduleInfoNode.getText());
        }
        
        if(pymntScheduleInfoNode.getName() == 'StartDate') {
            psResult.StartDate = DateTime.valueOf(getDateTimeString(pymntScheduleInfoNode.getText()));
        }
    
        if(pymntScheduleInfoNode.getName() == 'TotalAmount') {
            psResult.TotalAmount = Decimal.valueOf(pymntScheduleInfoNode.getText());
        }       
    }
    

    /** 
     * Helper method to parse the ScheduledOrdersResult node in the response XML
     * 
     * @param scheduledOrdersResNode    the ScheduledOrdersResult XML node element
     * @param soResult                  the MPPInterfaceHTTP.ScheduledOrdersResult object to be populated from node items
     */
    private static void populateScheduledOrdersResult(
        DOM.Xmlnode scheduledOrdersResNode, MPPInterfaceHTTP.ScheduledOrdersResult soResult) {
            
        if(scheduledOrdersResNode.getName() == 'Currency') {
            soResult.currencyUsed = scheduledOrdersResNode.getText();
        }
    
        if(scheduledOrdersResNode.getName() == 'OrderDate') {
            soResult.orderDate = DateTime.valueOf(getDateTimeString(scheduledOrdersResNode.getText()));
        }
    
        if(scheduledOrdersResNode.getName() == 'OrderID') {
            soResult.orderID = Integer.valueOf(scheduledOrdersResNode.getText());
        }
    
        if(scheduledOrdersResNode.getName() == 'OrderStatus') {
            soResult.orderStatus = getOrderStatus(scheduledOrdersResNode.getText());
        }
        
        if(scheduledOrdersResNode.getName() == 'PaymentMethod') {
            soResult.paymentMethod = getPaymentTypes(scheduledOrdersResNode.getText());
        }
    }
    
        
    /** 
     * Helper method to parse the PriceInformation node in the response XML
     * 
     * @param priceInformationNode  the PriceInformation XML node element
     * @param taxRes                the MPPInterfaceHTTP.TaxResult object to be populated from node items
     */
    private static void populatePriceInformation(
        DOM.Xmlnode priceInformationNode, MPPInterfaceHTTP.TaxResult taxRes) {

        if(priceInformationNode.getName() == 'GrossAmount') {
            taxRes.grossAmount = Decimal.valueOf(priceInformationNode.getText());
        }       
            
        if(priceInformationNode.getName() == 'NetAmount') {
            taxRes.netAmount = Decimal.valueOf(priceInformationNode.getText());
        }       

        if(priceInformationNode.getName() == 'TotalTaxAmount') {
            taxRes.totalTaxAmount = Decimal.valueOf(priceInformationNode.getText());
        }       

        if(priceInformationNode.getName() == 'TotalTaxPercentage') {
            taxRes.totalTaxPercentage = Decimal.valueOf(priceInformationNode.getText());
        }       
    }
    
    
    /** 
     * Helper method to parse the SubscriptionInformation node in the response XML
     * 
     * @param subsInfoNode      the SubscriptionInformation XML node element
     * @param subResult         the MPPInterfaceHTTP.SubscriptionResult object to be populated from node items
     */
    private static void populateSubscriptionInformation(DOM.Xmlnode subsInfoNode, MPPInterfaceHTTP.SubscriptionResult subResult) {

        if(subsInfoNode.getName() == 'ActualPrice') {
            subResult.actualPrice = Decimal.valueOf(subsInfoNode.getText());
        }
        
        if(subsInfoNode.getName() == 'AutoRenew') {
            subResult.autoRenew = Boolean.valueOf(subsInfoNode.getText());
        }

        if(subsInfoNode.getName() == 'Currency') {
            subResult.currencyUsed = subsInfoNode.getText();
        }

        if(subsInfoNode.getName() == 'LastBillingAmount') {
            subResult.lastBillingAmount = Decimal.valueOf(subsInfoNode.getText());
        }

        if(subsInfoNode.getName() == 'LastBillingCurrency') {
            subResult.lastBillingCurrency = subsInfoNode.getText();
        }

        if(subsInfoNode.getName() == 'LastBillingDate') {
            subResult.lastBillingDate = DateTime.valueOf(getDateTimeString(subsInfoNode.getText()));
        }

        if(subsInfoNode.getName() == 'LastPaymentDate') {
            subResult.lastPaymentDate = DateTime.valueOf(getDateTimeString(subsInfoNode.getText()));
        }

        if(subsInfoNode.getName() == 'NextPaymentDate') {
            subResult.nextPaymentDate = DateTime.valueOf(getDateTimeString(subsInfoNode.getText()));
        }

        if(subsInfoNode.getName() == 'ServicePriceId') {
            subResult.servicePriceId = Integer.valueOf(subsInfoNode.getText());
        }
    }
    
    
    /** 
     * Helper method to parse the LastBillingTaxResult node in the response XML
     * 
     * @param lastBillingTaxResNode     the LastBillingTaxResult XML node element
     * @param taxRes                    the MPPInterfaceHTTP.TaxResult object to be populated from node items
     */
    private static void populatLastBillingTaxResult(DOM.Xmlnode lastBillingTaxResNode, MPPInterfaceHTTP.TaxResult taxRes) {

        if(lastBillingTaxResNode.getName() == 'GrossAmount') {
            taxRes.grossAmount = Decimal.valueOf(lastBillingTaxResNode.getText());
        }

        if(lastBillingTaxResNode.getName() == 'NetAmount') {
            taxRes.netAmount = Decimal.valueOf(lastBillingTaxResNode.getText());
        }

        if(lastBillingTaxResNode.getName() == 'TotalTaxAmount') {
            taxRes.totalTaxAmount = Decimal.valueOf(lastBillingTaxResNode.getText());
        }

        if(lastBillingTaxResNode.getName() == 'TotalTaxPercentage') {
            taxRes.totalTaxPercentage = Decimal.valueOf(lastBillingTaxResNode.getText());
        }

    }   
    

    /** 
     * Helper method to parse the TaxRegionAmount node in the response XML
     * 
     * @param taxRegionAmtNode      the TaxRegionAmount XML node element
     * @param taxRegAmt             the MPPInterfaceHTTP.TaxRegionAmount object to be populated from node items
     */
    private static void populateTaxRegionAmount(DOM.Xmlnode taxRegionAmtNode, MPPInterfaceHTTP.TaxRegionAmount taxRegAmt) {

        if(taxRegionAmtNode.getName() == 'RegionName') {
            taxRegAmt.regionName = taxRegionAmtNode.getText();
        }

        if(taxRegionAmtNode.getName() == 'RegionType') {
            taxRegAmt.regionType = taxRegionAmtNode.getText();
        }

        if(taxRegionAmtNode.getName() == 'DisplayName') {
            taxRegAmt.displayName = taxRegionAmtNode.getText();
        }

        if(taxRegionAmtNode.getName() == 'TaxAmountForRegion') {
            taxRegAmt.taxAmountForRegion = Decimal.valueOf(taxRegionAmtNode.getText());
        }

        if(taxRegionAmtNode.getName() == 'TaxCategory') {
            taxRegAmt.taxCategory = taxRegionAmtNode.getText();
        }

        if(taxRegionAmtNode.getName() == 'TaxRateForRegion') {
            taxRegAmt.taxRateForRegion = Decimal.valueOf(taxRegionAmtNode.getText());
        }
    }
    

    /** 
     * Helper method to parse the SubscriptionPriceItems node in the response XML
     * 
     * @param subsPriceNode     the SubscriptionPriceItems XML node element
     * @param subsPriceItem     the MPPInterfaceHTTP.SubscriptionPriceItem object to be populated from node items
     */
    private static void populateSubscriptionPriceItem(DOM.Xmlnode subsPriceNode, MPPInterfaceHTTP.SubscriptionPriceItem subsPriceItem) {
        if(subsPriceNode.getName() == 'Description') {
            subsPriceItem.description = subsPriceNode.getText();
        }

        if(subsPriceNode.getName() == 'Price') {
            subsPriceItem.price = Decimal.valueOf(subsPriceNode.getText());
        }

        if(subsPriceNode.getName() == 'SupplierId') {
            subsPriceItem.supplierId = Integer.valueOf(subsPriceNode.getText());
        }

        if(subsPriceNode.getName() == 'ThirdPartyRef') {
            subsPriceItem.thirdPartyRef = subsPriceNode.getText();
        }
        
    }
    
    
    /**
     * Helper method to parse the PaymentMethod enum type and map to MPPInterfaceHTTP.PaymentTypes
     *
     * @param enumValue     the string read from PaymentMethod tag from the response XML
     * @return  mapping MPPInterfaceHTTP.PaymentTypes object to the enumValue
     */
    private static MPPInterfaceHTTP.PaymentTypes getPaymentTypes(String enumValue) {
        MPPInterfaceHTTP.PaymentTypes p;
        if(enumValue.equalsIgnoreCase('CreditDebitCard')) {
            p = MPPInterfaceHTTP.PaymentTypes.CREDITDEBITCARD;
        }
        if(enumValue.equalsIgnoreCase('ServiceCredit')) {
            p = MPPInterfaceHTTP.PaymentTypes.SERVICECREDIT;
        }
        if(enumValue.equalsIgnoreCase('ReverseBillSms')) {
            p = MPPInterfaceHTTP.PaymentTypes.REVERSEBILLSMS;
        }
        if(enumValue.equalsIgnoreCase('NotAvailable')) {
            p = MPPInterfaceHTTP.PaymentTypes.NOTAVAILABLE;
        }
        if(enumValue.equalsIgnoreCase('ActivationCode')) {
            p = MPPInterfaceHTTP.PaymentTypes.VOUCHERCODE;
        }
        if(enumValue.equalsIgnoreCase('DirectDebit')) {
            p = MPPInterfaceHTTP.PaymentTypes.DIRECTDEBIT;
        }
        if(enumValue.equalsIgnoreCase('Paypal')) {
            p = MPPInterfaceHTTP.PaymentTypes.PAYPAL;
        }
        
        return p;
    }
    
    
    /**
     * Helper method to parse the OrderStatus enum type and map to MPPInterfaceHTTP.OrderStatus
     *
     * @param enumValue     the string read from OrderStatus tag from the response XML
     * @return  mapping MPPInterfaceHTTP.OrderStatus object to the enumValue
     */
    private static MPPInterfaceHTTP.OrderStatus getOrderStatus(String enumValue) {
        MPPInterfaceHTTP.OrderStatus os;
        if(enumValue.equalsIgnoreCase('Created')) {
            os = MPPInterfaceHTTP.OrderStatus.CREATED;
        }
        if(enumValue.equalsIgnoreCase('New')) {
            os = MPPInterfaceHTTP.OrderStatus.NEWORDER;
        }
        if(enumValue.equalsIgnoreCase('Confirmed')) {
            os = MPPInterfaceHTTP.OrderStatus.CONFIRMED;
        }
        if(enumValue.equalsIgnoreCase('Dispatched')) {
            os = MPPInterfaceHTTP.OrderStatus.DISPATCHED;
        }
        if(enumValue.equalsIgnoreCase('Cancelled')) {
            os = MPPInterfaceHTTP.OrderStatus.CANCELLED;
        }
        if(enumValue.equalsIgnoreCase('Notified')) {
            os = MPPInterfaceHTTP.OrderStatus.NOTIFIED;
        }
        if(enumValue.equalsIgnoreCase('Reminder')) {
            os = MPPInterfaceHTTP.OrderStatus.REMINDER;
        }
        if(enumValue.equalsIgnoreCase('Completed')) {
            os = MPPInterfaceHTTP.OrderStatus.COMPLETED;
        }
        if(enumValue.equalsIgnoreCase('Refunded')) {
            os = MPPInterfaceHTTP.OrderStatus.REFUNDED;
        }
        if(enumValue.equalsIgnoreCase('Waiting')) {
            os = MPPInterfaceHTTP.OrderStatus.WAITING;
        }
        if(enumValue.equalsIgnoreCase('Downloaded')) {
            os = MPPInterfaceHTTP.OrderStatus.DOWNLOADED;
        }
        if(enumValue.equalsIgnoreCase('SuspectedDuplicate')) {
            os = MPPInterfaceHTTP.OrderStatus.SUSPECTEDDUPLICATE;
        }
        if(enumValue.equalsIgnoreCase('MaxRefunded')) {
            os = MPPInterfaceHTTP.OrderStatus.MAXREFUNDED;
        }
        if(enumValue.equalsIgnoreCase('PartialRefunded')) {
            os = MPPInterfaceHTTP.OrderStatus.PARTIALREFUNDED;
        }
        if(enumValue.equalsIgnoreCase('NeedToOrder')) {
            os = MPPInterfaceHTTP.OrderStatus.NEEDTOORDER;
        }
        if(enumValue.equalsIgnoreCase('ProductsOrdered')) {
            os = MPPInterfaceHTTP.OrderStatus.PRODUCTSORDERED;
        }
        if(enumValue.equalsIgnoreCase('Authorised')) {
            os = MPPInterfaceHTTP.OrderStatus.AUTHORISED;
        }
        
        return os;
    }
    
       
    
    /** 
     * A utility method to remove the occurence of T to form a valid string to be read as datetime field
     *
     * @param temp  the string read from the XML in format YYYY-MM-DDTHH:MM:SS
     * @return string in the format YYYY-MM-DD HH:MM:SS 
     */ 
    public static String getDateTimeString(String temp) {
        temp = temp.replace('T', ' ');
        return temp;
    }
    
    
    /** 
     * Method to form a dummy response to test Subscriptions BAU:PP-1631 
     *
     * @return test response for testing Subscriptions BAU:PP-1631
     */
    public static String getChangePaymentScheduleDateTestXML() {
        String testXMLResponse = '';

        testXMLResponse +=  '<ChangePaymentSchedulePaymentDateResult>';
        testXMLResponse +=     '<ErrorMessage/>';
        testXMLResponse +=     '<ErrorNumber/>';
        testXMLResponse +=     '<ChangedPaymentSchedules>';
        testXMLResponse +=        '<ChangePaymentSchedulePaymentDateItem>';
        testXMLResponse +=           '<ClientReference/>';
        testXMLResponse +=           '<ExpiryDate>2014-01-15T00:00:00</ExpiryDate>';
        testXMLResponse +=           '<NextPaymentDate>2013-01-13T00:00:00</NextPaymentDate>';
        testXMLResponse +=           '<PaymentScheduleId>12345</PaymentScheduleId>';
        testXMLResponse +=           '<DatedPayment>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-02-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-01-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-03-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=           '</DatedPayment>';
        testXMLResponse +=        '</ChangePaymentSchedulePaymentDateItem>';

        testXMLResponse +=        '<ChangePaymentSchedulePaymentDateItem>';
        testXMLResponse +=           '<ClientReference/>';
        testXMLResponse +=           '<ExpiryDate>2014-01-15T00:00:00</ExpiryDate>';
        testXMLResponse +=           '<NextPaymentDate>2013-01-13T00:00:00</NextPaymentDate>';
        testXMLResponse +=           '<PaymentScheduleId>49654</PaymentScheduleId>';
        testXMLResponse +=           '<DatedPayment>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-02-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-01-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=              '<DatedPaymentv7_5>';
        testXMLResponse +=                 '<Amount>125</Amount>';
        testXMLResponse +=                 '<Currency>GBP</Currency>';
        testXMLResponse +=                 '<OrderDate>2012-03-29T00:00:00</OrderDate>';
        testXMLResponse +=              '</DatedPaymentv7_5>';
        testXMLResponse +=           '</DatedPayment>';
        testXMLResponse +=        '</ChangePaymentSchedulePaymentDateItem>';
        testXMLResponse +=     '</ChangedPaymentSchedules>';
        testXMLResponse +=  '</ChangePaymentSchedulePaymentDateResult>';

        return testXMLResponse;
    }


    /** 
     * Method to form a dummy response to test Subscriptions BAU:PP-1862, PP-1615 & PP-1631 
     *
     * @return test response for testing Subscriptions BAU:PP-1862, PP-1615 & PP-1631
     */
    public static String getUserServicesTestXML() {
        String testXMLResponse = '';
        
        testXMLResponse += '<UserServicesResult>';
        testXMLResponse +=  '<ServiceInformation>';
        testXMLResponse +=      '<ServiceInformationResult>';
        testXMLResponse +=          '<ApplicationMessage></ApplicationMessage>';
        testXMLResponse +=          '<ApplicationMessage2></ApplicationMessage2>';
        testXMLResponse +=          '<ApplicationOfferName></ApplicationOfferName>';
        testXMLResponse +=          '<ExpiryDate>2013-05-27T00:00:00</ExpiryDate>';
        testXMLResponse +=          '<FirstNonDiscountedBillingPoint>2012-11-25T00:00:00</FirstNonDiscountedBillingPoint>';
        testXMLResponse +=          '<LastDiscountedBillingPoint>2012-08-25T00:00:00</LastDiscountedBillingPoint>';
        testXMLResponse +=          '<OfferName></OfferName>';
        testXMLResponse +=          '<OfferTypeId></OfferTypeId>';
        testXMLResponse +=          '<PaymentMethod>DirectDebit</PaymentMethod>';
        testXMLResponse +=          '<ServiceGroup>Premium Products</ServiceGroup>';
        testXMLResponse +=          '<ServiceID>11249</ServiceID>';
        testXMLResponse +=          '<ServiceStatus>2</ServiceStatus>';
        testXMLResponse +=          '<ServiceTitle>Print Pack</ServiceTitle>';
        testXMLResponse +=          '<VoucherCode></VoucherCode>';
        testXMLResponse +=          '<VoucherDiscountPrice>0</VoucherDiscountPrice>';
        testXMLResponse +=          '<PaymentScheduleInformation>';
        testXMLResponse +=              '<Frequency>Quarterly</Frequency>';
        testXMLResponse +=              '<PaymentDate>1</PaymentDate>';
        testXMLResponse +=              '<PaymentDateOffset>-2</PaymentDateOffset>';
        testXMLResponse +=              '<StartDate>2012-08-27T00:00:00</StartDate>';
        testXMLResponse +=              '<TotalAmount>338.0</TotalAmount>';
        testXMLResponse +=              '<ScheduleOrders>';
        testXMLResponse +=                  '<ScheduledOrdersResult>';
        testXMLResponse +=                      '<Currency>GBP</Currency>';
        testXMLResponse +=                      '<OrderDate>2012-08-23T00:00:00</OrderDate>';
        testXMLResponse +=                      '<OrderID>1962001</OrderID>';
        testXMLResponse +=                      '<OrderStatus>Completed</OrderStatus>';
        testXMLResponse +=                      '<PaymentMethod>DirectDebit</PaymentMethod>';
        testXMLResponse +=                      '<PriceInformation>';
        testXMLResponse +=                          '<GrossAmount>84.5000</GrossAmount>';
        testXMLResponse +=                          '<NetAmount>84.5000</NetAmount>';
        testXMLResponse +=                          '<TotalTaxAmount>0.0000</TotalTaxAmount>';
        testXMLResponse +=                          '<TotalTaxPercentage>0.00000</TotalTaxPercentage>';
        testXMLResponse +=                          '<TaxRegions>';
        testXMLResponse +=                              '<TaxRegionAmount>';
        testXMLResponse +=                                  '<RegionName>RegionName</RegionName>';
        testXMLResponse +=                                  '<RegionType>ZeroRated</RegionType>';
        testXMLResponse +=                                  '<DisplayName>DisplayName</DisplayName>';
        testXMLResponse +=                                  '<TaxAmountForRegion>0.0</TaxAmountForRegion>';
        testXMLResponse +=                                  '<TaxCategory>TaxCategory</TaxCategory>';
        testXMLResponse +=                                  '<TaxRateForRegion>0.0</TaxRateForRegion>';
        testXMLResponse +=                              '</TaxRegionAmount>';
        testXMLResponse +=                          '</TaxRegions>';
        testXMLResponse +=                      '</PriceInformation>';
        testXMLResponse +=                  '</ScheduledOrdersResult>';
        testXMLResponse +=              '</ScheduleOrders>';
        testXMLResponse +=          '</PaymentScheduleInformation>';
        
        testXMLResponse +=          '<SubscriptionInformation>';
        testXMLResponse +=              '<ActualPrice>0.0</ActualPrice>';
        testXMLResponse +=              '<AutoRenew>true</AutoRenew>';
        testXMLResponse +=              '<Currency>10</Currency>';
        testXMLResponse +=              '<LastBillingAmount>0.0</LastBillingAmount>';
        testXMLResponse +=              '<LastBillingCurrency>GBP</LastBillingCurrency>';
        testXMLResponse +=              '<LastBillingDate>2001-12-31T12:00:00</LastBillingDate>';
        testXMLResponse +=              '<LastPaymentDate>2001-12-31T12:00:00</LastPaymentDate>';
        testXMLResponse +=              '<NextPaymentDate>2001-12-31T12:00:00</NextPaymentDate>';
        testXMLResponse +=              '<ServicePriceId>0</ServicePriceId>';
        testXMLResponse +=              '<LastBillingTaxResult>';
        testXMLResponse +=                  '<GrossAmount>0.0</GrossAmount>';
        testXMLResponse +=                  '<NetAmount>0.0</NetAmount>';
        testXMLResponse +=                  '<TotalTaxAmount>0.0</TotalTaxAmount>';
        testXMLResponse +=                  '<TotalTaxPercentage>0.0</TotalTaxPercentage>';
        testXMLResponse +=                  '<TaxRegions>';
        testXMLResponse +=                      '<TaxRegionAmount>';
        testXMLResponse +=                      '<RegionName>RegionName</RegionName>';
        testXMLResponse +=                      '<RegionType>ZeroRated</RegionType>';
        testXMLResponse +=                      '<DisplayName>DisplayName</DisplayName>';
        testXMLResponse +=                      '<TaxAmountForRegion>0.0</TaxAmountForRegion>';
        testXMLResponse +=                      '<TaxCategory>TaxCategory</TaxCategory>';
        testXMLResponse +=                      '<TaxRateForRegion>0.0</TaxRateForRegion>';
        testXMLResponse +=                      '</TaxRegionAmount>';
        testXMLResponse +=                  '</TaxRegions>';
        testXMLResponse +=              '</LastBillingTaxResult>';
        testXMLResponse +=              '<SubscriptionPriceItems>';
        testXMLResponse +=                  '<Items>';
        testXMLResponse +=                      '<SubscriptionPriceItem>';
        testXMLResponse +=                          '<Description>Description</Description>';
        testXMLResponse +=                          '<Price>0.0</Price>';
        testXMLResponse +=                          '<SupplierId>0</SupplierId>';
        testXMLResponse +=                          '<ThirdPartyRef>ThirdPartyRef</ThirdPartyRef>';
        testXMLResponse +=                      '</SubscriptionPriceItem>';
        testXMLResponse +=                  '</Items>';
        testXMLResponse +=              '</SubscriptionPriceItems>';
        testXMLResponse +=          '</SubscriptionInformation>';
        testXMLResponse +=      '</ServiceInformationResult>';
        testXMLResponse +=  '</ServiceInformation>';
        testXMLResponse += '</UserServicesResult>';
        
        return testXMLResponse;
    }
    
    /** 
     * Method to form a dummy response to getUserInfo
     */
    public static String getUserInfoTestXML() {
        String testXMLResponse = '';
        
        testXMLResponse +=  '<UserInfoResult>';
        testXMLResponse +=  '<ErrorMessage></ErrorMessage>';
        testXMLResponse +=  '<ErrorNumber>0</ErrorNumber>';
        testXMLResponse +=  '    <AccountDetailParameters>';
        testXMLResponse +=  '       <AccountParameter>';
        testXMLResponse +=  '          <ParameterName>SAM_GUID</ParameterName>';
        testXMLResponse +=  '          <ParameterValue>7d7a3c51-019c-405a-934b-fb9b728e1eec</ParameterValue>';
        testXMLResponse +=  '       </AccountParameter>';
        testXMLResponse +=  '       <AccountParameter>';
        testXMLResponse +=  '          <ParameterName>TSNumber</ParameterName>';
        testXMLResponse +=  '          <ParameterValue>TS9899999</ParameterValue>';
        testXMLResponse +=  '       </AccountParameter>';
        testXMLResponse +=  '    </AccountDetailParameters>';
        testXMLResponse +=  '    <AccountStatus>Active</AccountStatus>';
        testXMLResponse +=  '    <AccountType>Unspecified</AccountType>';
        testXMLResponse +=  '    <Address>';
        testXMLResponse +=  '       <City/>';
        testXMLResponse +=  '       <Country/>';
        testXMLResponse +=  '       <District/>';
        testXMLResponse +=  '       <HouseFlatNumber/>';
        testXMLResponse +=  '       <HouseName/>';
        testXMLResponse +=  '       <PostCode/>';
        testXMLResponse +=  '       <Street/>';
        testXMLResponse +=  '    </Address>';
        testXMLResponse +=  '    <ClientUserId/>';
        testXMLResponse +=  '    <CreditCard xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">';
        testXMLResponse +=  '       <CreditCardType>Visa</CreditCardType>';
        testXMLResponse +=  '       <DateValidated>2013-09-16T11:40:57.787</DateValidated>';
        testXMLResponse +=  '       <ExpiryDate>04/15</ExpiryDate>';
        testXMLResponse +=  '       <IsValidated>true</IsValidated>';
        testXMLResponse +=  '       <LastFourDigits>1111</LastFourDigits>';
        testXMLResponse +=  '    </CreditCard>';
        testXMLResponse +=  '    <CreditsOnAccount xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">';
        testXMLResponse +=  '       <CreditAmounts/>';
        testXMLResponse +=  '    </CreditsOnAccount>';
        testXMLResponse +=  '    <DateOfBirth>0001-01-01T00:00:00</DateOfBirth>';
        testXMLResponse +=  '    <EmailAddress>dave.morris+duptest+20130916+3@telegraph.co.uk</EmailAddress>';
        testXMLResponse +=  '    <FirstName>d</FirstName>';
        testXMLResponse +=  '    <Gender>Male</Gender>';
        testXMLResponse +=  '    <Guid>9496a3c9d32b4374ba89fb51df637d03</Guid>';
        testXMLResponse +=  '    <HasFailedPostPayOrders>false</HasFailedPostPayOrders>';
        testXMLResponse +=  '    <Nickname>d</Nickname>';
        testXMLResponse +=  '    <PhoneNumbers xmlns:b="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
        testXMLResponse +=  '    <PreferredCurrency>GBP</PreferredCurrency>';
        testXMLResponse +=  '    <RequiresUserPassword>false</RequiresUserPassword>';
        testXMLResponse +=  '    <Surname>morris</Surname>';
        testXMLResponse +=  '    <UnpaidPostPayOrderBalance>0.0000</UnpaidPostPayOrderBalance>';
        testXMLResponse +=  '    <UserPassword>3y&amp;NzQ8?2}</UserPassword>';
        testXMLResponse +=  '</UserInfoResult>';
       
        
        return testXMLResponse;
    }    

    /** 
     * Method to form a dummy response to getUserInfo
     */
    public static String getUserOrderHistoryTestXML() {
        String testXMLResponse = '';
        
		testXMLResponse += '<UserOrderHistoryResult xmlns:a="MppGlobal.WCFServices.DataContract.Public.v7_15" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
		testXMLResponse += '    <ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
		testXMLResponse += '    <ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
		testXMLResponse += '    <a:OrderHistoryItems>';
		testXMLResponse += '       <a:OrderHistoryItem>';
		testXMLResponse += '          <a:Currency>GBP</a:Currency>';
		testXMLResponse += '          <a:OrderDateUTC>2014-05-15T19:52:38.083</a:OrderDateUTC>';
		testXMLResponse += '          <a:OrderDescription><![CDATA[Premium Subscription<div style="font-size:12px;"><br/>Subscription Price: £416.00<br/>Subscription Duration: 52Weeks<br/>Incentive: £50 M&S Voucher</div>]]></a:OrderDescription>';
		testXMLResponse += '          <a:OrderId>8032834</a:OrderId>';
		testXMLResponse += '          <a:Parameters xmlns:b="MppGlobal.iPay.BusinessObjects.DataContract.v4">';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>Originator</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>Salesforce</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>TCode</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>387V</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>OrderTakenMethod</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>Inbound</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>OrderTakenCompany</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>Chatham</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>OrderTakenByUser</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>System+Admin</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>IncentiveId</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>a082000000J2A44AAF</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>IncentiveDescription</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>£50 M&amp;S Voucher</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '          </a:Parameters>';
		testXMLResponse += '          <a:PaymentType>CreditCard</a:PaymentType>';
		testXMLResponse += '          <a:TaxResult>';
		testXMLResponse += '             <a:GrossAmount>416.0000</a:GrossAmount>';
		testXMLResponse += '             <a:NetAmount>416.0000</a:NetAmount>';
		testXMLResponse += '             <a:TaxRegions>';
		testXMLResponse += '                <a:TaxRegionAmount>';
		testXMLResponse += '                   <a:RegionName>ZeroRated</a:RegionName>';
		testXMLResponse += '                   <a:RegionType>ZeroRated</a:RegionType>';
		testXMLResponse += '                   <a:DisplayName>Zero Rated</a:DisplayName>';
		testXMLResponse += '                   <a:TaxAmountForRegion>0.0000</a:TaxAmountForRegion>';
		testXMLResponse += '                   <a:TaxCategory>Standard</a:TaxCategory>';
		testXMLResponse += '                   <a:TaxRateForRegion>0.00000</a:TaxRateForRegion>';
		testXMLResponse += '                </a:TaxRegionAmount>';
		testXMLResponse += '             </a:TaxRegions>';
		testXMLResponse += '             <a:TotalTaxAmount>0.0000</a:TotalTaxAmount>';
		testXMLResponse += '             <a:TotalTaxPercentage>0.00000</a:TotalTaxPercentage>';
		testXMLResponse += '          </a:TaxResult>';
		testXMLResponse += '       </a:OrderHistoryItem>';
		testXMLResponse += '       <a:OrderHistoryItem>';
		testXMLResponse += '          <a:Currency>GBP</a:Currency>';
		testXMLResponse += '          <a:OrderDateUTC>2014-06-03T12:56:57.953</a:OrderDateUTC>';
		testXMLResponse += '          <a:OrderDescription>Premium Subscription</a:OrderDescription>';
		testXMLResponse += '          <a:OrderId>8040549</a:OrderId>';
		testXMLResponse += '          <a:Parameters xmlns:b="MppGlobal.iPay.BusinessObjects.DataContract.v4">';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>Originator</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>Salesforce</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '             <b:OrderParameter>';
		testXMLResponse += '                <b:ParameterName>TCode</b:ParameterName>';
		testXMLResponse += '                <b:ParameterValue>387V</b:ParameterValue>';
		testXMLResponse += '             </b:OrderParameter>';
		testXMLResponse += '          </a:Parameters>';
		testXMLResponse += '          <a:PaymentType>CreditCard</a:PaymentType>';
		testXMLResponse += '          <a:TaxResult>';
		testXMLResponse += '             <a:GrossAmount>25.0000</a:GrossAmount>';
		testXMLResponse += '             <a:NetAmount>25.0000</a:NetAmount>';
		testXMLResponse += '             <a:TaxRegions>';
		testXMLResponse += '                <a:TaxRegionAmount>';
		testXMLResponse += '                   <a:RegionName>ZeroRated</a:RegionName>';
		testXMLResponse += '                   <a:RegionType>ZeroRated</a:RegionType>';
		testXMLResponse += '                   <a:DisplayName>Zero Rated</a:DisplayName>';
		testXMLResponse += '                   <a:TaxAmountForRegion>0.0000</a:TaxAmountForRegion>';
		testXMLResponse += '                   <a:TaxCategory>Standard</a:TaxCategory>';
		testXMLResponse += '                   <a:TaxRateForRegion>0.00000</a:TaxRateForRegion>';
		testXMLResponse += '                </a:TaxRegionAmount>';
		testXMLResponse += '             </a:TaxRegions>';
		testXMLResponse += '             <a:TotalTaxAmount>0.0000</a:TotalTaxAmount>';
		testXMLResponse += '             <a:TotalTaxPercentage>0.00000</a:TotalTaxPercentage>';
		testXMLResponse += '          </a:TaxResult>';
		testXMLResponse += '       </a:OrderHistoryItem>';
		testXMLResponse += '       <a:OrderHistoryItem>';
		testXMLResponse += '          <a:Currency>GBP</a:Currency>';
		testXMLResponse += '          <a:OrderDateUTC>2014-12-01T17:37:56.747</a:OrderDateUTC>';
		testXMLResponse += '          <a:OrderDescription>Refund Amount on Order: 8040549 (P1003517530_repeat_testmode)</a:OrderDescription>';
		testXMLResponse += '          <a:OrderId>8706604</a:OrderId>';
		testXMLResponse += '          <a:PaymentType>CreditCard</a:PaymentType>';
		testXMLResponse += '          <a:TaxResult>';
		testXMLResponse += '             <a:GrossAmount>15.0000</a:GrossAmount>';
		testXMLResponse += '             <a:NetAmount>15.0000</a:NetAmount>';
		testXMLResponse += '             <a:TaxRegions>';
		testXMLResponse += '                <a:TaxRegionAmount>';
		testXMLResponse += '                   <a:RegionName>ZeroRated</a:RegionName>';
		testXMLResponse += '                   <a:RegionType>ZeroRated</a:RegionType>';
		testXMLResponse += '                   <a:DisplayName>Zero Rated</a:DisplayName>';
		testXMLResponse += '                   <a:TaxAmountForRegion>0.0000</a:TaxAmountForRegion>';
		testXMLResponse += '                   <a:TaxCategory>Standard</a:TaxCategory>';
		testXMLResponse += '                   <a:TaxRateForRegion>0.00000</a:TaxRateForRegion>';
		testXMLResponse += '                </a:TaxRegionAmount>';
		testXMLResponse += '             </a:TaxRegions>';
		testXMLResponse += '             <a:TotalTaxAmount>0.0000</a:TotalTaxAmount>';
		testXMLResponse += '             <a:TotalTaxPercentage>0.00000</a:TotalTaxPercentage>';
		testXMLResponse += '          </a:TaxResult>';
		testXMLResponse += '       </a:OrderHistoryItem>';
		testXMLResponse += '    </a:OrderHistoryItems>';
		testXMLResponse += '    <a:TotalNumberOfOrders>3</a:TotalNumberOfOrders>';
		testXMLResponse += '</UserOrderHistoryResult>';
        
        return testXMLResponse;
    }    
    
}