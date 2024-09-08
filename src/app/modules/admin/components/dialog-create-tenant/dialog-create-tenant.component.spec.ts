import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DialogCreateTenantComponent } from './dialog-create-tenant.component';

describe('DialogCreateTenantComponent', () => {
  let component: DialogCreateTenantComponent;
  let fixture: ComponentFixture<DialogCreateTenantComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DialogCreateTenantComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(DialogCreateTenantComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
