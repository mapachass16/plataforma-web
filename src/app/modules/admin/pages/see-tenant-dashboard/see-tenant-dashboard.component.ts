import { ChangeDetectionStrategy, Component, AfterViewInit, ViewChild } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatPaginator, MatPaginatorIntl, MatPaginatorModule } from '@angular/material/paginator';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { Router } from '@angular/router'; // Corrige el import de Router
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { CommonModule } from '@angular/common';

const Users = [
  {
    name: "Paula Chaves",
    email: "p.chaves@example.com",
    role: "Owner"
  },
  {
    name: "Carlos Mendoza",
    email: "c.mendoza@example.com",
    role: "User"
  },
  {
    name: "Laura Gómez",
    email: "l.gomez@example.com",
    role: "User"
  },
  {
    name: "Juan Pérez",
    email: "j.perez@example.com",
    role: "User"
  },
  {
    name: "Ana Martínez",
    email: "a.martinez@example.com",
    role: "User"
  }
];

const SENIORCITIZER = [
  {
    name: "Alberto Campos",
    email: "p.chaves@example.com",
    role: "Owner"
  },
  {
    name: "Carlos Mendoza",
    email: "c.mendoza@example.com",
    role: "User"
  },
  {
    name: "Laura Gómez",
    email: "l.gomez@example.com",
    role: "User"
  },
  {
    name: "Juan Pérez",
    email: "j.perez@example.com",
    role: "User"
  },
  {
    name: "Ana Martínez",
    email: "a.martinez@example.com",
    role: "User"
  }
];

@Component({
  selector: 'app-see-tenant-dashboard',
  standalone: true,
  imports: [MatCardModule, MatInputModule, MatFormFieldModule, MatTableModule, MatSortModule, MatPaginatorModule, MatButtonModule, MatIconModule, MatTooltipModule, CommonModule],
  templateUrl: './see-tenant-dashboard.component.html',
  styleUrls: ['./see-tenant-dashboard.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SeeTenantDashboardComponent implements AfterViewInit {
  displayedUsersColumns: string[] = ['name', 'email', 'role', 'actions'];
  dataSourceUsers: MatTableDataSource<any>;

  @ViewChild(MatPaginator) usersPaginator: MatPaginator;
  @ViewChild(MatSort) usersSort: MatSort;

  constructor(private _router: Router) {
    this.dataSourceUsers = new MatTableDataSource(Users);
  }

  ngAfterViewInit() {
    this.dataSourceUsers.paginator = this.usersPaginator;
    this.dataSourceUsers.sort = this.usersSort;
  }

  applyFilterUsers(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceUsers.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceUsers.paginator) {
      this.dataSourceUsers.paginator.firstPage();
    }
  }
}
