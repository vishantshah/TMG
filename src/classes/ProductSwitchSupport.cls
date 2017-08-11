/**
* @author Wiktor Czykin
* @date 05/05/2016
* @description Interface to be able to trigger product switch action from within product switch component
#############Change Log#############
Modified by     Version     Change Date
**/
public interface ProductSwitchSupport{
	void changeProductId(Id productId);
	void prepareProductListBeforeView(List<TCodeProductWrapper> products);
}