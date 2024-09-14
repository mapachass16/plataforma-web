import { Injectable } from '@angular/core';

export const HEROES: any[] = [
  { id: 12, name: 'Dr. Nice' },
  { id: 13, name: 'Bombasto' },
  { id: 14, name: 'Celeritas' },
  { id: 15, name: 'Magneta' },
  { id: 16, name: 'RubberMan' },
  { id: 17, name: 'Dynama' },
  { id: 18, name: 'Dr. IQ' },
  { id: 19, name: 'Magma' },
  { id: 20, name: 'Tornado' }
];



@Injectable({
  providedIn: 'root'
})
export class HeroService {

  constructor() { }


  getHeroes(): any[] {
    return HEROES;
  }
}
