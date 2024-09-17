import { ChangeDetectionStrategy, Component, AfterViewInit, ViewChild, inject } from '@angular/core';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatPaginator, MatPaginatorIntl, MatPaginatorModule } from '@angular/material/paginator';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog } from '@angular/material/dialog';
import { DialogCreateTenantComponent } from '../../components/dialog-create-tenant/dialog-create-tenant.component';
import { MatTooltipModule } from '@angular/material/tooltip';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { SupabaseService } from '../../../../services/supabase.service';
import { ChangeDetectorRef } from '@angular/core';


const NAMES = [
  'Familia Pérez',
  'Familia Gómez',
  'Familia Rodríguez',
  'Familia Fernández',
  'Familia López',
  'Familia Martínez',
  'Familia González',
  'Familia Sánchez',
  'Familia Díaz',
  'Familia Castro'
];

const OWNERS: string[] = [
  'Maia S',
  'Asher G',
  'Olivia D',
  'Atticus T',
  'Amelia Q',
  'Jack R',
  'Charlotte V',
  'Theodore H',
  'Isla O',
  'Oliver A',
  'Isabella P',
  'Jasper R',
  'Cora N',
  'Levi L',
  'Violet P',
  'Arthur S',
  'Mia A',
  'Thomas J',
  'Elizabeth K',
];

const OPTIONS: string[] = [
  'On', 'Off'
];


@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [MatCardModule, MatInputModule, MatFormFieldModule, MatInputModule, MatTableModule, MatSortModule, MatPaginatorModule, MatButtonModule, MatIconModule, MatTooltipModule, CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardComponent implements AfterViewInit {
  accounts: number;
  users: number;
  monitored: number;
  devicesIoT: number;
  dialog = inject(MatDialog);
  tenants: any[];
  id: any;
  user: any;

  displayedColumns: string[] = ['id', 'account', 'owner', 'users', 'devices', 'deviceIoT', 'status', 'actions'];
  dataSource: MatTableDataSource<any>;

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(
    public _MatPaginatorIntl: MatPaginatorIntl,
    private _router: Router,
    private _supabaseService: SupabaseService,
    private cdr: ChangeDetectorRef
  ) {
    const users = Array.from({ length: 10 }, (_, k) => createNewUser(k + 1));
    this.dataSource = new MatTableDataSource(users);
  }

  async ngOnInit() {
    this.user = await this._supabaseService.getUserSession();
    if (this.user.data.user.role === "service_role") {
      await this.getAllTenants();
    } else {
      await this.getUserTenants();
    }
    this.accounts = this.tenants.length;
    this.getTenantMembers(this.tenants);
    this.getMonitoredPeople(this.tenants);
    this.getIoTDevicesByTenant(this.tenants);
    this.createDataForTable(this.tenants)
    this.cdr.detectChanges();
  }

  ngAfterViewInit() {
    if (this.paginator && this.sort) {
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
      if (this.paginator._intl) {
        this.paginator._intl.itemsPerPageLabel = "Cuentas por página";
      }
    }
  }


  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();

    if (this.dataSource.paginator) {
      this.dataSource.paginator.firstPage();
    }
  }

  private async getAllTenants() {
    try {
      const { data, error } = await this._supabaseService.getAllTenants();

      if (error) {
        console.error("Error al obtener todos los tenants:", error.message);
        return;
      }
      this.tenants = data;
    } catch (e) {
      console.error("Ocurrió un error inesperado:", e);
    }
  }

  private async getUserTenants() {
    try {
      const { data, error } = await this._supabaseService.getTenants();

      if (error) {
        console.error("Error al obtener los tenants del usuario:", error.message);
        return;
      }
      this.tenants = data;
    } catch (e) {
      console.error("Ocurrió un error inesperado:", e);
    }
  }

  private async getTenantMembers(tenants: any[]) {
    if (this.user.data.user.role === "service_role") {
      this.users = 0;

      const promises = tenants.map(async (tenant: any) => {
        const { data, error } = await this._supabaseService.getTenantMembersService(tenant.tenant_id);

        if (error) {
          console.error(`Error al obtener los usuarios monitorizados para tenant ${tenant.tenant_id}:`, error);
          return 0;
        }
        return data?.length ?? 0;
      });

      const results = await Promise.all(promises);
      this.users = results.reduce((acc, curr) => acc + curr, 0);
      this.cdr.detectChanges();
    }
    else {
      try {
        const tenantId = this.user.data.user.id;
        const { data, error } = await this._supabaseService.getTenantMembers(tenantId);

        if (error) {
          console.error('Error al obtener los miembros del tenant:', error.message);
          throw error;
        }
        this.users = data.length;
        this.cdr.detectChanges();
      } catch (e) {
        console.error('Error en la función getTenantMembers:', e);
        throw e;
      }
    }

  }

  private async getMonitoredPeople(tenants: any) {
    if (this.user.data.user.role === "service_role") {
      this.monitored = 0;

      const promises = tenants.map(async (tenant: any) => {
        const { data, error } = await this._supabaseService.getMonitoredPeople(tenant.tenant_id);

        if (error) {
          console.error(`Error al obtener los usuarios monitorizados para tenant ${tenant.tenant_id}:`, error);
          return 0;
        }
        return data?.length ?? 0;
      });

      const results = await Promise.all(promises);
      this.monitored = results.reduce((acc, curr) => acc + curr, 0);
      this.cdr.detectChanges();
    } else {
      try {
        const tenantId = this.user.data.user.id;
        const { data, error } = await this._supabaseService.getMonitoredPeople(tenantId);

        if (error) {
          console.error('Error al obtener los usuarios monitorizados:', error.message);
          throw error;
        }
        this.monitored = data.length;
        this.cdr.detectChanges();
      } catch (e) {
        console.error('Error en la función getMonitoredPeople:', e);
        throw e;
      }
    }
  }

  private async getIoTDevicesByTenant(tenants: any) {
    if (this.user.data.user.role === "service_role") {
      this.devicesIoT = 0;

      const promises = tenants.map(async (tenant: any) => {
        const { data, error } = await this._supabaseService.getIoTDevicesByTenant(tenant.tenant_id);

        if (error) {
          console.error(`Error al obtener los dispositivos IoT para cada tenant ${tenant.tenant_id}:`, error);
          return 0;
        }
        return data?.length ?? 0;
      });

      const results = await Promise.all(promises);
      this.devicesIoT = results.reduce((acc, curr) => acc + curr, 0);

      this.cdr.detectChanges();
    } else {
      try {
        const tenantId = this.user.data.user.id;
        const { data, error } = await this._supabaseService.getIoTDevicesByTenant(tenantId);

        if (error) {
          console.error('Error al obtener los dispositivos IoT del tenant:', error.message);
          throw error;
        }
        this.devicesIoT = data.length;
        this.cdr.detectChanges();
      } catch (e) {
        console.error('Error en la función getIoTDevicesByTenant:', e);
        throw e;
      }
    }
  }

  public seeDetails(id: string) {
    this._router.navigate(['/admin/see-tenant-dashboard', id]);
  }

  public deleteTenant(id: string) {
    const filteredData = this.dataSource.data.filter((element: any) => element.id !== id);
    this.dataSource.data = filteredData;
  }

  public createTenant() {
    this.dialog.open(DialogCreateTenantComponent, {
      width: '30%',
      height: 'auto',
    });
  }

  private async createDataForTable(tenants: any) {
    const promises = tenants.map(async (tenant: any) => {
      const id = tenant.tenant_id;
      const account = tenant.name;
      if (this.user.data.user.role === "service_role") {
        const users = await (await this._supabaseService.getTenantMembersService(id)).data;
        //console.log(users)
        const usersAmount = users.length;
        const ownerData = users.filter((item: any) => item.tenant_role === 'owner');
        console.log(ownerData[0]);
      }


      /*const { data, error } = await this._supabaseService.getIoTDevicesByTenant(tenant.tenant_id);

      if (error) {
        console.error(`Error al obtener los dispositivos IoT para cada tenant ${tenant.tenant_id}:`, error);
        return 0;
      }
      return data?.length ?? 0;*/
    });

    //const results = await Promise.all(promises);
    //this.devicesIoT = results.reduce((acc, curr) => acc + curr, 0);

    //this.cdr.detectChanges();
  }
}



/** Builds and returns a new User. */
function createNewUser(id: number): any {
  const name =
    NAMES[Math.round(Math.random() * (NAMES.length - 1))];

  const owner =
    OWNERS[Math.round(Math.random() * (OWNERS.length - 1))];

  return {
    id: id.toString(),
    account: name,
    owner: owner,
    users: Math.floor(Math.random() * 10) + 1,
    devices: Math.floor(Math.random() * 10) + 1,
    deviceIoT: OPTIONS[Math.floor(Math.random() * OPTIONS.length)],
    status: OPTIONS[Math.floor(Math.random() * OPTIONS.length)]
  };

}


