package intern.sapo.be.controller;

import intern.sapo.be.dto.request.Inventory.ListIdRequest;
import intern.sapo.be.dto.response.Product.Inventory.InventoryResponse;
import intern.sapo.be.entity.Inventory;
import intern.sapo.be.service.IInventoryService;
import lombok.AllArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@AllArgsConstructor
@RequestMapping("/inventories")
@CrossOrigin("*")
public class InventoryController {
	private final IInventoryService iInventoryService;

	@GetMapping("/pagination")
	public ResponseEntity getPagination(@RequestParam(value = "pageNumber", required = true, defaultValue = "1") int pageNumber,
										@RequestParam(value = "pageSize", required = true, defaultValue = "10") int pageSize,
										@RequestParam(value = "sortBy", required = false) String sortBy,
										@RequestParam(value = "sortDir", required = false) String sortDir)
	{
		Page<Inventory> Inventory = iInventoryService.findAllBypPage(pageNumber,pageSize,sortBy,sortDir);
		Map<String,Object> results = new HashMap<>();
		results.put("data", Inventory.getContent());
		results.put("total", Inventory.getTotalElements());
		results.put("from", Inventory.getSize() * Inventory.getNumber() + 1);
		results.put("to", Inventory.getSize() * Inventory.getNumber() + Inventory.getNumberOfElements());

		return ResponseEntity.ok(results);
	}

	@GetMapping("")
	public List<Inventory> getAll() {
		return iInventoryService.findAll();
	}


	@GetMapping("/active")
	public List<Inventory> getAllActiveInventory() {
		return iInventoryService.findAllActiveInventory();
	}

	@PostMapping("")
	public Inventory createInventory(@RequestBody @Valid Inventory inventory, BindingResult bindingResult) {
		return iInventoryService.create(inventory, bindingResult);
	}


	@GetMapping("/{id}")
	public Inventory getById(@PathVariable(value = "id") Integer id) {
		return iInventoryService.findById(id);
	}

	@PutMapping("/{id}")

	public Inventory update(@RequestBody @Valid Inventory inventory, BindingResult bindingResult,
							@PathVariable(value = "id") Integer id) {
		return iInventoryService.update(id, inventory, bindingResult);
	}

	@PutMapping("/delete/{id}")
	public void deleteInventory(@PathVariable(value = "id") Integer id) {
		iInventoryService.delete(id)
		;
	}

	@GetMapping("/productvariant/{id}")
	public InventoryResponse getAll(@PathVariable(value = "id") Integer id, @RequestParam(value = "name") String name)
	{
		return iInventoryService.getProductVariantByInventoryId(id, name);
	}

	@PostMapping("/delete")
	public void deleteProductVariant(@RequestBody ListIdRequest listIdRequest)
	{
		iInventoryService.deleteListProductVanriant(listIdRequest);
	}

}