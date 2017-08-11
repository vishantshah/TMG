/**
* Author:       Gavin Palmer (Accenture)
* Date:         21/04/2016
* Description:  Create a mock responce for the Core API callout
*
* ******************* Change Log *******************
* Modified by       Change Date     Description
**/
@isTest
public class GetAllOfferCodesHTTPResponceMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        CoreApiResources.CoreApiOffers allOffersObj = new CoreApiResources.CoreApiOffers();
        allOffersObj.offers = new List<CoreApiResources.CoreApiOfferDetails>();
        
        //Tablet UK Offer Details
        //1.Monthly
        CoreApiResources.CoreApiOfferDetails tabletUKMonthlyObj = new CoreApiResources.CoreApiOfferDetails();
        tabletUKMonthlyObj.name='Test TabletUKMonthly';
        tabletUKMonthlyObj.description='Test TabletUKMonthly Description';
        tabletUKMonthlyObj.longDescription='Test TabletUKMonthly Lond Description';
        tabletUKMonthlyObj.containsFreeTrial=false;
        tabletUKMonthlyObj.isRestricted=true;
        tabletUKMonthlyObj.friendlyName='Test TabletUKMonthly';
        tabletUKMonthlyObj.tmgId='Test TabletUKMonthly';
        tabletUKMonthlyObj.frequency=Constants.PRODUCT_FREQUENCY_MONTHLY;
        tabletUKMonthlyObj.product=Constants.TABLET_UK_PRODUCT_NAME;
        allOffersObj.offers.add(tabletUKMonthlyObj);
        
        //2. Annual
        CoreApiResources.CoreApiOfferDetails tabletUKAnnualObj = new CoreApiResources.CoreApiOfferDetails();
        tabletUKAnnualObj.name='Test TabletUKAnnual';
        tabletUKAnnualObj.description='Test TabletUKAnnual Description';
        tabletUKAnnualObj.longDescription='Test TabletUKAnnual Lond Description';
        tabletUKAnnualObj.containsFreeTrial=false;
        tabletUKAnnualObj.isRestricted=true;
        tabletUKAnnualObj.friendlyName='Test TabletUKAnnual';
        tabletUKAnnualObj.tmgId='Test TabletUKAnnual';
        tabletUKAnnualObj.frequency=Constants.PRODUCT_FREQUENCY_ANNUAL;
        tabletUKAnnualObj.product=Constants.TABLET_UK_PRODUCT_NAME;
        allOffersObj.offers.add(tabletUKAnnualObj);

        //Tablet International Offer Deals
        //1. Monthly
        CoreApiResources.CoreApiOfferDetails tabletInternationalMonthlyObj = new CoreApiResources.CoreApiOfferDetails();
        tabletInternationalMonthlyObj.name='Test TabletInternationaMonthly';
        tabletInternationalMonthlyObj.description='Test TabletInternationaMonthly Description';
        tabletInternationalMonthlyObj.longDescription='Test TabletInternationaMonthly Lond Description';
        tabletInternationalMonthlyObj.containsFreeTrial=false;
        tabletInternationalMonthlyObj.isRestricted=true;
        tabletInternationalMonthlyObj.friendlyName='Test TabletInternationaMonthly';
        tabletInternationalMonthlyObj.tmgId='Test TabletInternationaMonthly';
        tabletInternationalMonthlyObj.frequency=Constants.PRODUCT_FREQUENCY_MONTHLY;
        tabletInternationalMonthlyObj.product=Constants.TABLET_INTERNATIONAL_PRODUCT_NAME;
        allOffersObj.offers.add(tabletInternationalMonthlyObj);
        
        //2. Annual
        CoreApiResources.CoreApiOfferDetails tabletInternationalAnnualObj = new CoreApiResources.CoreApiOfferDetails();
        tabletInternationalAnnualObj.name='Test TabletInternationaAnnual';
        tabletInternationalAnnualObj.description='Test TabletInternationaAnnual Description';
        tabletInternationalAnnualObj.longDescription='Test TabletInternationaAnnual Lond Description';
        tabletInternationalAnnualObj.containsFreeTrial=false;
        tabletInternationalAnnualObj.isRestricted=true;
        tabletInternationalAnnualObj.friendlyName='Test TabletInternationaAnnual';
        tabletInternationalAnnualObj.tmgId='Test TabletInternationaAnnual';
        tabletInternationalAnnualObj.frequency=Constants.PRODUCT_FREQUENCY_ANNUAL;
        tabletInternationalAnnualObj.product=Constants.TABLET_INTERNATIONAL_PRODUCT_NAME;
        allOffersObj.offers.add(tabletInternationalAnnualObj);
        
        //Website UK offer codes
        //1. Monthly
        CoreApiResources.CoreApiOfferDetails websiteMonthlyObj = new CoreApiResources.CoreApiOfferDetails();
        websiteMonthlyObj.name='Test WebsiteMonthly';
        websiteMonthlyObj.description='Test WebsiteMonthly Description';
        websiteMonthlyObj.longDescription='Test WebsiteMonthly Lond Description';
        websiteMonthlyObj.containsFreeTrial=false;
        websiteMonthlyObj.isRestricted=true;
        websiteMonthlyObj.friendlyName='Test WebsiteMonthly';
        websiteMonthlyObj.tmgId='Test WebsiteMonthly';
        websiteMonthlyObj.frequency=Constants.PRODUCT_FREQUENCY_MONTHLY;
        websiteMonthlyObj.product=Constants.WEBSITE_UK_PRODUCT_NAME;
        allOffersObj.offers.add(websiteMonthlyObj);

        //2. Annual
        CoreApiResources.CoreApiOfferDetails websiteAnnualObj = new CoreApiResources.CoreApiOfferDetails();
        websiteAnnualObj.name='Test WebsiteAnnual';
        websiteAnnualObj.description='Test WebsiteAnnual Description';
        websiteAnnualObj.longDescription='Test WebsiteAnnual Lond Description';
        websiteAnnualObj.containsFreeTrial=false;
        websiteAnnualObj.isRestricted=false;
        websiteAnnualObj.friendlyName='Test WebsiteAnnual';
        websiteAnnualObj.tmgId='Test WebsiteAnnual';
        websiteAnnualObj.frequency=Constants.PRODUCT_FREQUENCY_ANNUAL;
        websiteAnnualObj.product=Constants.WEBSITE_UK_PRODUCT_NAME;
        allOffersObj.offers.add(websiteAnnualObj);
        
        //Website Annual offer codes
        //1. Monthly
        CoreApiResources.CoreApiOfferDetails websiteIntMonthlyObj = new CoreApiResources.CoreApiOfferDetails();
        websiteIntMonthlyObj.name='Test websiteIntMonthlyObj';
        websiteIntMonthlyObj.description='Test websiteIntMonthlyObj Description';
        websiteIntMonthlyObj.longDescription='Test websiteIntMonthlyObj Lond Description';
        websiteIntMonthlyObj.containsFreeTrial=false;
        websiteIntMonthlyObj.isRestricted=false;
        websiteIntMonthlyObj.friendlyName='Test websiteIntMonthlyObj';
        websiteIntMonthlyObj.tmgId='Test websiteIntMonthlyObj';
        websiteIntMonthlyObj.frequency=Constants.PRODUCT_FREQUENCY_MONTHLY;
        websiteIntMonthlyObj.product=Constants.WEBSITE_INTERNATIONAL_PRODUCT_NAME;
        allOffersObj.offers.add(websiteIntMonthlyObj);

        //2. Annual
        CoreApiResources.CoreApiOfferDetails websiteIntAnnualObj = new CoreApiResources.CoreApiOfferDetails();
        websiteIntAnnualObj.name='Test websiteIntAnnualObj';
        websiteIntAnnualObj.description='Test websiteIntAnnualObj Description';
        websiteIntAnnualObj.longDescription='Test websiteIntAnnualObj Lond Description';
        websiteIntAnnualObj.containsFreeTrial=false;
        websiteIntAnnualObj.isRestricted=false;
        websiteIntAnnualObj.friendlyName='Test websiteIntAnnualObj';
        websiteIntAnnualObj.tmgId='Test websiteIntAnnualObj';
        websiteIntAnnualObj.frequency=Constants.PRODUCT_FREQUENCY_ANNUAL;
        websiteIntAnnualObj.product=Constants.WEBSITE_INTERNATIONAL_PRODUCT_NAME;
        allOffersObj.offers.add(websiteIntAnnualObj);

        String body = JSON.serialize(allOffersObj);

        HttpResponse response = new HttpResponse();
        
        response.setBody(body);
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        return response;
    }

}