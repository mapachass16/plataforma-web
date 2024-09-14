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
import { Router } from '@angular/router';
import { SupabaseService } from '../../../../services/supabase.service';


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
  accounts: number = 50;
  users: number = 30;
  monitored: number = 20;
  devices: number = 10;
  readonly dialog = inject(MatDialog);
  tenants: any[]

  displayedColumns: string[] = ['id', 'account', 'owner', 'users', 'devices', 'deviceIoT', 'status', 'actions'];
  dataSource: MatTableDataSource<any>;

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(
    public _MatPaginatorIntl: MatPaginatorIntl,
    private _router: Router,
    private _supabaseService: SupabaseService
  ) {
    const users = Array.from({ length: 10 }, (_, k) => createNewUser(k + 1));
    this.dataSource = new MatTableDataSource(users);
  }

  async ngOnInit() {
    await this.getTenants()
  }

  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
    this.paginator._intl.itemsPerPageLabel = "Cuentas por página";
  }

  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();

    if (this.dataSource.paginator) {
      this.dataSource.paginator.firstPage();
    }
  }

  async getTenants() {
    try {
      const { data, error } = await this._supabaseService.getTenants();

      if (error) {
        console.error("Error al obtener los tenants:", error.message);
        return;
      }

      console.log("Tenants obtenidos:", data);

    } catch (e) {
      console.error("Ocurrió un error inesperado:", e);

    }
  }


  public seeDetails(id: string) {
    this._router.navigate(['/admin/see-tenant-dashboard', id]);
  }

  public deleteTenant(name: string) {
    console.log(name)
  }

  public createTenant() {
    this.dialog.open(DialogCreateTenantComponent, {
      width: '30%',
      height: 'auto',
    });
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


